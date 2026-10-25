#!/usr/bin/env bash
# =============================================================================
# install-spark.sh — Cấu hình Spark-on-YARN trên 1 node (Tuần 2)
# Đỗ Minh Hiển (24139013). Chạy TRÊN TỪNG NODE:  sudo bash install-spark.sh
# =============================================================================
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Cần sudo" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPARK_HOME=/opt/spark
APP_USER="${SUDO_USER:-ec2-user}"; [[ "$APP_USER" == root ]] && APP_USER=ec2-user

install -m 644 -o "$APP_USER" "${ROOT}/conf/spark/spark-defaults.conf" "${SPARK_HOME}/conf/"

JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
cat > "${SPARK_HOME}/conf/spark-env.sh" <<EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
# Spark bản without-hadoop: dùng thư viện của Hadoop 3.3.6 đã cài + jar S3A ở tools/lib
export SPARK_DIST_CLASSPATH="\$(/opt/hadoop/bin/hadoop classpath):/opt/hadoop/share/hadoop/tools/lib/*"
export PYSPARK_PYTHON=python3
export SPARK_LOG_DIR=/data/hadoop/logs
EOF
chown "$APP_USER:" "${SPARK_HOME}/conf/spark-env.sh"
echo "[$(hostname)] install-spark xong"
