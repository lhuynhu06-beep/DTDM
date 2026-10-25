#!/usr/bin/env bash
# stop-cluster.sh — Dừng Spark History, JobHistory, YARN, HDFS (chạy trên hadoop-master). Đỗ Minh Hiển (24139013)
set -uo pipefail
# shellcheck disable=SC1091
source /etc/profile.d/bigdata.sh
"$SPARK_HOME/sbin/stop-history-server.sh"
mapred --daemon stop historyserver
stop-yarn.sh
stop-dfs.sh
jps
