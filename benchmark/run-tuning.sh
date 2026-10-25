#!/usr/bin/env bash
# =============================================================================
# run-tuning.sh — Tuần 4: so sánh trước/sau tối ưu Spark trên CÙNG một cụm (chạy trên hadoop-master)
#   BUCKET=... SIZE=1 RUNS=3 bash ~/DTDM/benchmark/run-tuning.sh
#
# baseline : 3 executor × 1 core × 1g, driver 1g (container 1536 MB × 4 = toàn bộ 6144 MB)
#            1 GB text = 8 file × 128 MB → 8 task / 3 core → 3 "đợt", đợt cuối chỉ dùng 2/3 core
# tuned    : 2 executor × 2 core × 1600m, driver 512m → 4 core thay vì 3 (container 2048×2 + 1024)
#            + spark.sql.files.maxPartitionBytes=64m → 16 task, chia đều hơn trên 4 core
# =============================================================================
set -uo pipefail
: "${BUCKET:?cần BUCKET}"
SIZE="${SIZE:-1}"; RUNS="${RUNS:-3}"; JOB="${JOB:-wordcount}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNED="--conf spark.executor.instances=2 --conf spark.executor.cores=2 --conf spark.executor.memory=1600m \
--conf spark.driver.memory=512m --conf spark.sql.files.maxPartitionBytes=67108864"

BUCKET="$BUCKET" TAG=tune-baseline SIZES="$SIZE" RUNS="$RUNS" JOBS="$JOB" EXTRA="" bash "$DIR/run-benchmark.sh"
BUCKET="$BUCKET" TAG=tuned SIZES="$SIZE" RUNS="$RUNS" JOBS="$JOB" EXTRA="$TUNED" bash "$DIR/run-benchmark.sh"
