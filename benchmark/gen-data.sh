#!/usr/bin/env bash
# =============================================================================
# gen-data.sh — Sinh dữ liệu 1/3/5 GB (text + CSV) lên S3 bằng chính cụm Spark (chạy trên hadoop-master)
#   BUCKET=... bash ~/DTDM/benchmark/gen-data.sh
# Sinh 40 part × 128 MB (= 5 GB) rồi copy phía server 8 part → 1g/, 24 part → 3g/.
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
source /etc/profile.d/bigdata.sh
: "${BUCKET:?cần BUCKET}"
JOB=~/DTDM/jobs/gen_data.py
for kind in text csv; do
  if aws s3 ls "s3://${BUCKET}/data/${kind}/5g/_SUCCESS" >/dev/null 2>&1; then
    echo "data/${kind}/5g đã có, bỏ qua"; continue
  fi
  echo "== Sinh ${kind} 5 GB =="
  spark-submit --deploy-mode cluster --name "gen-${kind}-5g" "$JOB" "$kind" "s3a://${BUCKET}/data/${kind}/5g" 40 128
  aws s3 cp --recursive "s3://${BUCKET}/data/${kind}/5g/" "s3://${BUCKET}/data/${kind}/1g/" \
    --exclude '*' --include 'part-0000[0-7]' --only-show-errors
  aws s3 cp --recursive "s3://${BUCKET}/data/${kind}/5g/" "s3://${BUCKET}/data/${kind}/3g/" \
    --exclude '*' --include 'part-0000*' --include 'part-0001*' --include 'part-0002[0-3]' --only-show-errors
done
for kind in text csv; do for s in 1g 3g 5g; do
  printf '%-5s %-3s ' "$kind" "$s"
  aws s3 ls --summarize --human-readable --recursive "s3://${BUCKET}/data/${kind}/${s}/" | grep -E 'Total (Objects|Size)' | tr '\n' ' '; echo
done; done
