#!/usr/bin/env bash
# =============================================================================
# run-benchmark.sh — Benchmark cụm tự dựng theo plan: 3 mức dữ liệu × 3 lần × 2 job (chạy trên hadoop-master)
#   BUCKET=... bash ~/DTDM/benchmark/run-benchmark.sh                 # cấu hình mặc định (baseline)
#   BUCKET=... TAG=tuned SIZES="5" JOBS=wordcount EXTRA="--conf ..." bash run-benchmark.sh
# Thời gian đo = wall-clock của spark-submit --deploy-mode cluster (gồm cả xin container YARN),
# giống cách tính thời gian 1 Step trên EMR. Kết quả nối vào ~/DTDM/benchmark/results-self-managed.csv
# và sao lên s3://BUCKET/results/self-managed/.
# =============================================================================
set -uo pipefail
# shellcheck disable=SC1091
source /etc/profile.d/bigdata.sh
: "${BUCKET:?cần BUCKET}"
SIZES="${SIZES:-1 3 5}"; RUNS="${RUNS:-3}"; JOBS="${JOBS:-wordcount aggregation}"
TAG="${TAG:-baseline}"; EXTRA="${EXTRA:-}"
OUT=~/DTDM/benchmark/results-self-managed.csv
LOGDIR=~/DTDM/benchmark/logs; mkdir -p "$LOGDIR"
[[ -f "$OUT" ]] || echo "cluster,config,job,size_gb,run,seconds,exit_code,app_id,finished_utc,instance_type,nodes" > "$OUT"

for size in $SIZES; do
  for job in $JOBS; do
    [[ "$job" == wordcount ]] && in="s3a://${BUCKET}/data/text/${size}g/" || in="s3a://${BUCKET}/data/csv/${size}g/"
    for run in $(seq 1 "$RUNS"); do
      out="s3a://${BUCKET}/results/self-managed/${TAG}/${job}/${size}g/run${run}-$(date +%s)"
      log="${LOGDIR}/${TAG}-${job}-${size}g-run${run}.log"
      t0=$(date +%s.%N)
      # shellcheck disable=SC2086
      name="bench-${TAG}-${job}-${size}g-r${run}"
      spark-submit --deploy-mode cluster --name "$name" $EXTRA \
        ~/DTDM/jobs/${job}.py "$in" "$out" > "$log" 2>&1
      rc=$?
      t1=$(date +%s.%N)
      secs=$(python3 -c "print(round(${t1}-${t0},1))")
      # Trạng thái cuối lấy thẳng từ YARN (log client của spark-submit có thể trống trên cụm này)
      read -r app fin < <(yarn application -list -appStates ALL 2>/dev/null \
                          | awk -v n="$name" '$2==n {print $1, $7}' | sort | tail -1)
      if [[ $rc -eq 0 && "${fin:-}" != SUCCEEDED ]]; then rc=2; fi
      echo "self-managed,${TAG},${job},${size},${run},${secs},${rc},${app},$(date -u +%FT%TZ),t3.medium,1m+2w" | tee -a "$OUT"
    done
  done
done
aws s3 cp "$OUT" "s3://${BUCKET}/results/self-managed/results-self-managed.csv" --only-show-errors
python3 - "$OUT" <<'PY'
import csv, sys, statistics as st
from collections import defaultdict
g = defaultdict(list)
for r in csv.DictReader(open(sys.argv[1])):
    if r["exit_code"] == "0":
        g[(r["config"], r["job"], int(r["size_gb"]))].append(float(r["seconds"]))
print(f"{'config':10} {'job':12} {'GB':>3} {'n':>2} {'mean_s':>8} {'stdev':>6}")
for k in sorted(g):
    v = g[k]
    print(f"{k[0]:10} {k[1]:12} {k[2]:>3} {len(v):>2} {st.mean(v):>8.1f} {st.pstdev(v):>6.1f}")
PY
