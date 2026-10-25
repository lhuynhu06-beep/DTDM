#!/usr/bin/env bash
# =============================================================================
# start-cluster.sh — Khởi động HDFS + YARN + History Server (chạy trên hadoop-master, user ec2-user)
# Đỗ Minh Hiển (24139013)
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
source /etc/profile.d/bigdata.sh

start-dfs.sh
start-yarn.sh
mapred --daemon start historyserver || true

echo "Chờ NameNode thoát safe mode…"
hdfs dfsadmin -safemode wait

hdfs dfs -mkdir -p /spark-logs /spark /yarn-logs /tmp
hdfs dfs -chmod 1777 /tmp
# Jar Spark đặt sẵn trên HDFS (spark.yarn.archive) – chỉ tạo lần đầu
if ! hdfs dfs -test -e /spark/spark-libs.zip; then
  echo "Tạo spark-libs.zip trên HDFS"
  (cd "$SPARK_HOME/jars" && python3 -m zipfile -c /tmp/spark-libs.zip ./*.jar)
  hdfs dfs -put -f /tmp/spark-libs.zip /spark/ && rm -f /tmp/spark-libs.zip
fi
"$SPARK_HOME/sbin/start-history-server.sh" || true

echo "=== jps (master) ==="; jps
echo "=== hdfs dfsadmin -report ==="; hdfs dfsadmin -report | grep -E 'Live datanodes|^Name:|DFS Remaining:|Configured Capacity:'
echo "=== yarn node -list ==="; yarn node -list 2>/dev/null
