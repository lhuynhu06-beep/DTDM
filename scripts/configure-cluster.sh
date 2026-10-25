#!/usr/bin/env bash
# =============================================================================
# configure-cluster.sh — Tuần 2: đẩy cấu hình lên 3 node, cài Hadoop/Spark config, format + khởi động cụm
# Đỗ Minh Hiển (24139013). Chạy ở CloudShell sau bootstrap-cluster.sh:
#   ./scripts/configure-cluster.sh            # cấu hình + start
#   ./scripts/configure-cluster.sh --no-start # chỉ cấu hình
# =============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/infra/cluster.env"
KEY="${KEY:-$HOME/.ssh/id_ed25519}"
SSH_OPTS=(-i "$KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -o BatchMode=yes)
declare -A PUB=( [hadoop-master]="$MASTER_PUBLIC_IP" [hadoop-worker1]="$WORKER1_PUBLIC_IP" [hadoop-worker2]="$WORKER2_PUBLIC_IP" )
NODES=(hadoop-master hadoop-worker1 hadoop-worker2)

for n in "${NODES[@]}"; do
  echo "→ ${n}: chép repo (conf, scripts, jobs, benchmark, monitoring)"
  tar -C "$ROOT" -czf - conf scripts jobs benchmark monitoring 2>/dev/null \
    | ssh "${SSH_OPTS[@]}" "ec2-user@${PUB[$n]}" 'mkdir -p ~/DTDM && tar -C ~/DTDM -xzf -'
  ssh "${SSH_OPTS[@]}" "ec2-user@${PUB[$n]}" \
    'sudo bash ~/DTDM/scripts/install-hadoop.sh && sudo bash ~/DTDM/scripts/install-spark.sh'
done

[[ "${1:-}" == --no-start ]] && exit 0
ssh "${SSH_OPTS[@]}" "ec2-user@${PUB[hadoop-master]}" 'bash ~/DTDM/scripts/start-cluster.sh'
