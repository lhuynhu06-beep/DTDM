#!/usr/bin/env bash
# =============================================================================
# cleanup.sh — Tuần 4: dọn sạch tài nguyên nhánh self-managed (Đỗ Minh Hiển – 24139013)
#   ./infra/cleanup.sh            # liệt kê những gì SẼ xoá (dry-run)
#   ./infra/cleanup.sh --yes      # xoá thật: stack CFN, 3 EC2 + EBS, SG, dashboard/alarm, artifacts/ + data/ trên S3
#   KEEP_BUCKET=0 ./infra/cleanup.sh --yes   # xoá luôn bucket (mặc định GIỮ results/ để nộp)
# KHÔNG HOÀN TÁC ĐƯỢC – chỉ chạy sau khi đã quay demo và lưu đủ minh chứng.
# =============================================================================
set -uo pipefail
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}" AWS_PAGER=""
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "${ROOT}/infra/cluster.env" ]] && source "${ROOT}/infra/cluster.env"
STACK="${STACK:-hadoop-cfn}"; KEEP_BUCKET="${KEEP_BUCKET:-1}"; DO="${1:-}"
run() { if [[ "$DO" == --yes ]]; then echo "+ $*"; "$@"; else echo "[dry-run] $*"; fi; }

echo "== CloudFormation stack ${STACK} =="
aws cloudformation describe-stacks --stack-name "$STACK" --query 'Stacks[0].StackStatus' --output text 2>/dev/null \
  && { run aws cloudformation delete-stack --stack-name "$STACK";
       [[ "$DO" == --yes ]] && aws cloudformation wait stack-delete-complete --stack-name "$STACK"; }

echo "== EC2 cụm hadoop-selfmanaged (EBS DeleteOnTermination=true) =="
IDS=$(aws ec2 describe-instances --filters Name=tag:Cluster,Values=hadoop-selfmanaged \
      'Name=instance-state-name,Values=pending,running,stopping,stopped' --query 'Reservations[].Instances[].InstanceId' --output text)
if [[ -n "$IDS" ]]; then
  # shellcheck disable=SC2086
  run aws ec2 terminate-instances --instance-ids $IDS
  # shellcheck disable=SC2086
  [[ "$DO" == --yes ]] && aws ec2 wait instance-terminated --instance-ids $IDS
fi
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=hadoop-selfmanaged-sg --query 'SecurityGroups[0].GroupId' --output text)
[[ "$SG" != None && -n "$SG" ]] && run aws ec2 delete-security-group --group-id "$SG"

echo "== EBS volume/snapshot còn sót (tag Owner=24139013) =="
for v in $(aws ec2 describe-volumes --filters Name=tag:Owner,Values=24139013 Name=status,Values=available --query 'Volumes[].VolumeId' --output text); do
  run aws ec2 delete-volume --volume-id "$v"; done
for s in $(aws ec2 describe-snapshots --owner-ids self --filters Name=tag:Owner,Values=24139013 --query 'Snapshots[].SnapshotId' --output text); do
  run aws ec2 delete-snapshot --snapshot-id "$s"; done

echo "== CloudWatch dashboard + alarm =="
for d in $(aws cloudwatch list-dashboards --dashboard-name-prefix HadoopSelfManaged --query 'DashboardEntries[].DashboardName' --output text); do
  run aws cloudwatch delete-dashboards --dashboard-names "$d"; done
ALARMS=$(aws cloudwatch describe-alarms --alarm-name-prefix hadoop- --query 'MetricAlarms[].AlarmName' --output text)
# shellcheck disable=SC2086
[[ -n "$ALARMS" ]] && run aws cloudwatch delete-alarms --alarm-names $ALARMS

if [[ -n "${BUCKET:-}" ]]; then
  echo "== S3 ${BUCKET} =="
  run aws s3 rm "s3://${BUCKET}/data/" --recursive --only-show-errors
  run aws s3 rm "s3://${BUCKET}/artifacts/" --recursive --only-show-errors
  if [[ "$KEEP_BUCKET" == 0 ]]; then run aws s3 rb "s3://${BUCKET}" --force; else echo "Giữ s3://${BUCKET}/results/ để nộp"; fi
fi
echo "== Còn lại (nên rỗng) =="
aws ec2 describe-instances --filters Name=tag:Owner,Values=24139013 \
  'Name=instance-state-name,Values=pending,running,stopping,stopped' --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output table
