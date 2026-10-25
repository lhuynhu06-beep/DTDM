#!/usr/bin/env bash
# fix-status.sh — Sửa cột exit_code/app_id của results-self-managed.csv theo trạng thái thật trên YARN
# (dùng cho các lần chạy trước khi run-benchmark.sh được sửa). Chạy trên master của cụm đã chạy benchmark.
set -euo pipefail
# shellcheck disable=SC1091
source /etc/profile.d/bigdata.sh
CSV=~/DTDM/benchmark/results-self-managed.csv
yarn application -list -appStates ALL 2>/dev/null | awk 'NR>2 {print $2, $1, $7}' > /tmp/yarn-apps.txt
python3 - "$CSV" /tmp/yarn-apps.txt <<'PY'
import csv, sys
apps = {}
for line in open(sys.argv[2]):
    p = line.split()
    if len(p) == 3 and p[0].startswith("bench-"):
        apps[p[0]] = (p[1], p[2])
rows = list(csv.DictReader(open(sys.argv[1])))
for r in rows:
    name = f"bench-{r['config']}-{r['job']}-{r['size_gb']}g-r{r['run']}"
    if name in apps:
        r["app_id"], fin = apps[name]
        r["exit_code"] = "0" if fin == "SUCCEEDED" else (r["exit_code"] if r["exit_code"] != "0" else "2")
w = csv.DictWriter(open(sys.argv[1], "w", newline=""), fieldnames=rows[0].keys())
w.writeheader(); w.writerows(rows)
print(open(sys.argv[1]).read())
PY
