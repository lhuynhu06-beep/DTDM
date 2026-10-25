#!/usr/bin/env bash
# setup-cloudwatch-agent.sh — Cài CloudWatch Agent (CPU, RAM, Disk) trên 1 node. Đỗ Minh Hiển (24139013)
#   sudo bash ~/DTDM/monitoring/setup-cloudwatch-agent.sh
# Quyền ghi metric lấy từ LabInstanceProfile (cloudwatch:PutMetricData), không dùng access key.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Cần sudo" >&2; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rpm -q amazon-cloudwatch-agent >/dev/null 2>&1 || dnf -y -q install amazon-cloudwatch-agent
install -m 644 "${DIR}/cloudwatch-agent.json" /opt/aws/amazon-cloudwatch-agent/etc/hadoop-agent.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/hadoop-agent.json -s
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep -E '"status"|"configstatus"'
