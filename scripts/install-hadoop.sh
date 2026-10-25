#!/usr/bin/env bash
# =============================================================================
# install-hadoop.sh — Cấu hình HDFS + YARN trên 1 node (Tuần 2)
# Đỗ Minh Hiển (24139013). Chạy TRÊN TỪNG NODE sau setup-base.sh:
#   sudo bash install-hadoop.sh            # thư mục conf/hadoop nằm cạnh scripts/ (../conf/hadoop)
# Trên hadoop-master: format NameNode nếu chưa format (chỉ lần đầu, idempotent).
# =============================================================================
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Cần sudo" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_SRC="${ROOT}/conf/hadoop"
HADOOP_HOME=/opt/hadoop
APP_USER="${SUDO_USER:-ec2-user}"; [[ "$APP_USER" == root ]] && APP_USER=ec2-user
NODE=$(hostname)

[[ -d "$CONF_SRC" ]] || { echo "Không thấy ${CONF_SRC}" >&2; exit 1; }
echo "[$NODE] Chép cấu hình Hadoop"
install -m 644 -o "$APP_USER" "$CONF_SRC"/{core-site.xml,hdfs-site.xml,yarn-site.xml,mapred-site.xml,workers} \
  "${HADOOP_HOME}/etc/hadoop/"

# Nạp hadoop-aws + aws-java-sdk-bundle (S3A) vào classpath của các lệnh hadoop/hdfs
ENVF="${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
sed -i '/^export HADOOP_OPTIONAL_TOOLS=/d' "$ENVF"
echo 'export HADOOP_OPTIONAL_TOOLS="hadoop-aws"' >> "$ENVF"

echo "[$NODE] Tạo thư mục dữ liệu"
install -d -o "$APP_USER" -g "$APP_USER" /data/hadoop/{nn,dn,snn,tmp,s3a} /data/hadoop/logs
sed -i '/^export HADOOP_LOG_DIR=/d' "$ENVF"
echo 'export HADOOP_LOG_DIR=/data/hadoop/logs' >> "$ENVF"

if [[ "$NODE" == hadoop-master && ! -f /data/hadoop/nn/current/VERSION ]]; then
  echo "[$NODE] Format NameNode (lần đầu)"
  sudo -u "$APP_USER" bash -lc 'hdfs namenode -format -nonInteractive -clusterId hadoop-selfmanaged' 2>&1 | tail -3
fi
echo "[$NODE] install-hadoop xong"
