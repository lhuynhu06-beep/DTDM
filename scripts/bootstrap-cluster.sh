#!/usr/bin/env bash
# =============================================================================
# bootstrap-cluster.sh — Chạy setup-base.sh trên cả 3 node + bật SSH không mật khẩu
# Nhánh Self-managed – Đỗ Minh Hiển (24139013)
#
# Chạy ở máy đã chạy infra/ec2-cluster.sh (có infra/cluster.env):
#   ./scripts/bootstrap-cluster.sh                       # dùng ~/.ssh/id_ed25519 (key đã nạp qua user-data)
#   KEY=~/labsuser.pem ./scripts/bootstrap-cluster.sh    # hoặc key pair "vockey" (Learner Lab → AWS Details → Download PEM)
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/infra/cluster.env"
KEY="${KEY:-$HOME/.ssh/id_ed25519}"
SSH_USER="${SSH_USER:-ec2-user}"
LOG_DIR="${ROOT}/logs/bootstrap-$(date '+%Y%m%d-%H%M%S')"

[[ -f "$ENV_FILE" ]] || { echo "Thiếu ${ENV_FILE} — chạy ./infra/ec2-cluster.sh env trước" >&2; exit 1; }
[[ -f "$KEY" ]]      || { echo "Không thấy key ${KEY}" >&2; exit 1; }
chmod 600 "$KEY"
# shellcheck disable=SC1090
source "$ENV_FILE"
mkdir -p "$LOG_DIR"

SSH_OPTS=(-i "$KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -o BatchMode=yes)
declare -A PUB=( [hadoop-master]="$MASTER_PUBLIC_IP" [hadoop-worker1]="$WORKER1_PUBLIC_IP" [hadoop-worker2]="$WORKER2_PUBLIC_IP" )
NODES=(hadoop-master hadoop-worker1 hadoop-worker2)

rssh() { local n="$1"; shift; ssh "${SSH_OPTS[@]}" "${SSH_USER}@${PUB[$n]}" "$@"; }

# 1. Chép script + cluster.env, chạy song song trên 3 node (log riêng từng node)
pids=()
for n in "${NODES[@]}"; do
  (
    scp "${SSH_OPTS[@]}" -q "${ROOT}/scripts/setup-base.sh" "$ENV_FILE" "${SSH_USER}@${PUB[$n]}:/tmp/"
    rssh "$n" "sudo bash /tmp/setup-base.sh $n"
  ) > "${LOG_DIR}/${n}.log" 2>&1 &
  pids+=($!)
  echo "→ ${n} (${PUB[$n]}) đang cài… log: ${LOG_DIR}/${n}.log"
done
fail=0
for i in "${!pids[@]}"; do
  if wait "${pids[$i]}"; then echo "✓ ${NODES[$i]}"; else echo "✗ ${NODES[$i]} — xem log"; fail=1; fi
done
(( fail == 0 )) || exit 1

# 2. Phân phối public key của master sang authorized_keys của cả 3 node
MASTER_KEY=$(rssh hadoop-master 'cat ~/.ssh/id_ed25519.pub')
for n in "${NODES[@]}"; do
  rssh "$n" "grep -qxF '${MASTER_KEY}' ~/.ssh/authorized_keys || echo '${MASTER_KEY}' >> ~/.ssh/authorized_keys"
done

# 3. Kiểm tra: từ master SSH không mật khẩu tới mọi node bằng hostname
echo "Kiểm tra SSH không mật khẩu từ master:"
rssh hadoop-master 'for h in hadoop-master hadoop-worker1 hadoop-worker2 localhost 0.0.0.0; do printf "  %-15s → " "$h"; ssh -o BatchMode=yes "$h" "hostname; " || echo FAIL; done' \
  | tee "${LOG_DIR}/ssh-check.log"
echo "Hoàn tất. Log: ${LOG_DIR}"
