#!/usr/bin/env bash
# =============================================================================
# setup-base.sh — Chuẩn bị nền cho 1 node của cụm Hadoop/Spark tự dựng
# Nhánh Self-managed – Đỗ Minh Hiển (24139013) – Tuần 1
#
# Chạy TRÊN TỪNG NODE (Amazon Linux 2023 hoặc Ubuntu 22.04/24.04):
#   sudo bash setup-base.sh hadoop-master
#   sudo bash setup-base.sh hadoop-worker1
#   sudo bash setup-base.sh hadoop-worker2
#
# Việc script làm (idempotent — chạy lại nhiều lần không hỏng):
#   1. Đặt hostname
#   2. Ghi /etc/hosts bằng PRIVATE IP (không đổi khi Stop/Start, khác public IP)
#        - lấy từ cluster.env cạnh script (do infra/ec2-cluster.sh sinh ra), hoặc
#        - tự tìm theo tag Cluster/Name qua AWS CLI + LabInstanceProfile
#   3. Cài OpenJDK 11 (Amazon Corretto 11 trên AL2023), python3, rsync…
#   4. Tải + kiểm tra SHA-512 Hadoop 3.3.6 và Spark 3.5.5 (bản "without-hadoop")
#   5. Ghi biến môi trường /etc/profile.d/bigdata.sh, spark-env.sh
#   6. Tạo SSH key cho user hadoop trên master + cấu hình SSH nội bộ cụm
#      (việc chép public key sang worker do scripts/bootstrap-cluster.sh làm)
#
# Lý do chọn Spark "without-hadoop": Spark dùng đúng thư viện Hadoop 3.3.6 đã cài
# (SPARK_DIST_CLASSPATH=$(hadoop classpath)), nên ở Tuần 2 chỉ cần hadoop-aws-3.3.6
# + aws-java-sdk-bundle-1.12.367 là S3A khớp phiên bản, tránh lỗi NoSuchMethodError
# khi trộn hadoop-aws với hadoop-client 3.3.4 đóng gói sẵn trong spark-*-bin-hadoop3.
# =============================================================================
set -euo pipefail

NODE="${1:-}"
case "$NODE" in
  hadoop-master|hadoop-worker1|hadoop-worker2) ;;
  *) echo "Usage: sudo bash $0 {hadoop-master|hadoop-worker1|hadoop-worker2}" >&2; exit 2 ;;
esac
[[ $EUID -eq 0 ]] || { echo "Cần chạy bằng sudo" >&2; exit 1; }

HADOOP_VERSION="${HADOOP_VERSION:-3.3.6}"
SPARK_VERSION="${SPARK_VERSION:-3.5.5}"
CLUSTER="hadoop-selfmanaged"
INSTALL_DIR=/opt
DATA_DIR=/data/hadoop                       # dùng ở Tuần 2 cho dfs.namenode/datanode dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_USER="${SUDO_USER:-}"
if [[ -z "$APP_USER" || "$APP_USER" == root ]]; then
  if id ec2-user &>/dev/null; then APP_USER=ec2-user; else APP_USER=ubuntu; fi
fi
APP_HOME=$(getent passwd "$APP_USER" | cut -d: -f6)

log() { printf '\n[%s][%s] %s\n' "$(date '+%H:%M:%S')" "$NODE" "$*"; }

# ---------- 1. hostname --------------------------------------------------------
log "1/6 Đặt hostname = ${NODE}"
hostnamectl set-hostname "$NODE"

# ---------- 2. /etc/hosts -----------------------------------------------------
log "2/6 Ghi /etc/hosts bằng private IP"
if [[ -f "${SCRIPT_DIR}/cluster.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/cluster.env"
else
  echo "Không thấy cluster.env → tự tìm node theo tag Cluster=${CLUSTER}"
  TOKEN=$(curl -fsS -X PUT http://169.254.169.254/latest/api/token \
            -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')
  REGION=$(curl -fsS -H "X-aws-ec2-metadata-token: ${TOKEN}" \
            http://169.254.169.254/latest/meta-data/placement/region)
  ip_of() {
    aws ec2 describe-instances --region "$REGION" \
      --filters "Name=tag:Cluster,Values=${CLUSTER}" "Name=tag:Name,Values=$1" \
                'Name=instance-state-name,Values=pending,running' \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
  }
  MASTER_IP=$(ip_of hadoop-master)
  WORKER1_IP=$(ip_of hadoop-worker1)
  WORKER2_IP=$(ip_of hadoop-worker2)
fi
for v in MASTER_IP WORKER1_IP WORKER2_IP; do
  [[ "${!v:-None}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Thiếu/sai ${v}" >&2; exit 1; }
done
sed -i '/# BEGIN hadoop-cluster/,/# END hadoop-cluster/d' /etc/hosts
cat >> /etc/hosts <<EOF
# BEGIN hadoop-cluster
${MASTER_IP}  hadoop-master
${WORKER1_IP}  hadoop-worker1
${WORKER2_IP}  hadoop-worker2
# END hadoop-cluster
EOF
grep -A4 'BEGIN hadoop-cluster' /etc/hosts

# ---------- 3. gói hệ thống + Java 11 -------------------------------------------
log "3/6 Cài Java 11 và tiện ích"
. /etc/os-release
if [[ "$ID" == "amzn" ]]; then
  dnf -y -q install java-11-amazon-corretto-headless python3 rsync tar gzip which procps-ng
elif [[ "$ID" == "ubuntu" ]]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get -qq update
  apt-get -qq -y install openjdk-11-jdk-headless python3 rsync curl
else
  echo "OS ${ID} chưa hỗ trợ" >&2; exit 1
fi
JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
java -version 2>&1 | head -1

# ---------- 4. tải Hadoop + Spark ---------------------------------------------
fetch() { # $1 = đường dẫn tương đối trên mirror Apache, $2 = file đích
  local rel="$1" out="$2" m
  for m in https://dlcdn.apache.org https://archive.apache.org/dist; do
    if curl -fsSL --retry 3 -o "$out" "${m}/${rel}" && \
       curl -fsSL --retry 3 -o "${out}.sha512" "${m}/${rel}.sha512"; then
      local want got
      want=$(tr -d ' \r\n' < "${out}.sha512" | grep -oiE '[0-9a-f]{128}' | head -1 | tr 'A-F' 'a-f')
      got=$(sha512sum "$out" | awk '{print $1}')
      if [[ -n "$want" && "$want" == "$got" ]]; then echo "  OK sha512 ${out##*/} (${m})"; return 0; fi
      echo "  sha512 lệch ở ${m}, thử mirror khác" >&2
    fi
  done
  echo "Không tải được ${rel}" >&2; return 1
}

install_tgz() { # $1 rel-path, $2 tên thư mục giải nén, $3 symlink
  local rel="$1" dir="$2" link="$3" tgz="/tmp/${1##*/}"
  if [[ -d "${INSTALL_DIR}/${dir}" ]]; then
    echo "  ${dir} đã có, bỏ qua"
  else
    fetch "$rel" "$tgz"
    tar -xzf "$tgz" -C "$INSTALL_DIR"
    rm -f "$tgz" "${tgz}.sha512"
  fi
  ln -sfn "${INSTALL_DIR}/${dir}" "${INSTALL_DIR}/${link}"
  chown -R "${APP_USER}:" "${INSTALL_DIR}/${dir}"
}

log "4/6 Tải Hadoop ${HADOOP_VERSION} và Spark ${SPARK_VERSION}"
install_tgz "hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
            "hadoop-${HADOOP_VERSION}" hadoop
install_tgz "spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz" \
            "spark-${SPARK_VERSION}-bin-without-hadoop" spark
mkdir -p "$DATA_DIR" && chown -R "${APP_USER}:" /data

# ---------- 5. biến môi trường ------------------------------------------------
log "5/6 Ghi biến môi trường"
cat > /etc/profile.d/bigdata.sh <<EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${INSTALL_DIR}/hadoop
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export SPARK_HOME=${INSTALL_DIR}/spark
export PYSPARK_PYTHON=python3
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$SPARK_HOME/bin:\$SPARK_HOME/sbin
EOF
# start-dfs.sh/start-yarn.sh ssh sang node khác dưới dạng non-login shell → cần JAVA_HOME ở đây
sed -i "s|^#\? *export JAVA_HOME=.*|export JAVA_HOME=${JAVA_HOME}|" \
  "${INSTALL_DIR}/hadoop/etc/hadoop/hadoop-env.sh"
# Spark without-hadoop: nạp classpath của Hadoop đã cài
cat > "${INSTALL_DIR}/spark/conf/spark-env.sh" <<EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_CONF_DIR=${INSTALL_DIR}/hadoop/etc/hadoop
export SPARK_DIST_CLASSPATH=\$(${INSTALL_DIR}/hadoop/bin/hadoop classpath)
export PYSPARK_PYTHON=python3
EOF
chown "${APP_USER}:" "${INSTALL_DIR}/spark/conf/spark-env.sh"

# ---------- 6. SSH nội bộ cụm -------------------------------------------------
log "6/6 Cấu hình SSH nội bộ"
SSH_DIR="${APP_HOME}/.ssh"
install -d -m 700 -o "$APP_USER" -g "$APP_USER" "$SSH_DIR"
cat > "${SSH_DIR}/config" <<'EOF'
Host hadoop-master hadoop-worker1 hadoop-worker2 localhost 0.0.0.0
  StrictHostKeyChecking accept-new
  UserKnownHostsFile ~/.ssh/known_hosts
  IdentityFile ~/.ssh/id_ed25519
EOF
chown "${APP_USER}:" "${SSH_DIR}/config"; chmod 600 "${SSH_DIR}/config"
if [[ "$NODE" == hadoop-master && ! -f "${SSH_DIR}/id_ed25519" ]]; then
  sudo -u "$APP_USER" ssh-keygen -q -t ed25519 -N '' -C "hadoop@${NODE}" -f "${SSH_DIR}/id_ed25519"
fi

# ---------- kiểm tra ----------------------------------------------------------
log "Kiểm tra"
sudo -u "$APP_USER" bash -lc 'hostname; java -version 2>&1 | head -1; hadoop version | head -1; spark-submit --version 2>&1 | grep -m1 -o "version [0-9.]*"'
[[ "$NODE" == hadoop-master ]] && { echo "Public key của master:"; cat "${SSH_DIR}/id_ed25519.pub"; }
log "XONG"
