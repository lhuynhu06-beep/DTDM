#!/usr/bin/env bash
# =============================================================================
# s3-bucket.sh — Tạo bucket S3 riêng cho nhánh self-managed (Đỗ Minh Hiển – 24139013)
#   ./infra/s3-bucket.sh                 # tạo bucket (idempotent) + upload jobs/
# Bucket: Block Public Access, mã hoá SSE-S3 mặc định, tag Project/Owner, cấu trúc data/ jobs/ logs/ results/
# =============================================================================
set -euo pipefail
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}" AWS_PAGER=""
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${BUCKET:-hadoop-spark-24139013-${ACCOUNT}}"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Bucket ${BUCKET} đã có"
else
  aws s3api create-bucket --bucket "$BUCKET" >/dev/null   # us-east-1: không cần LocationConstraint
  echo "Đã tạo bucket ${BUCKET}"
fi
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging \
  'TagSet=[{Key=Project,Value=HadoopSpark-EC2-vs-EMR},{Key=Owner,Value=24139013}]'
for p in data/ jobs/ logs/ results/ artifacts/; do aws s3api put-object --bucket "$BUCKET" --key "$p" >/dev/null; done
aws s3 sync "${ROOT}/jobs" "s3://${BUCKET}/jobs/" --exclude '__pycache__/*' --only-show-errors
sed -i '/^BUCKET=/d' "${ROOT}/infra/cluster.env" 2>/dev/null || true
echo "BUCKET=${BUCKET}" >> "${ROOT}/infra/cluster.env"
echo "s3://${BUCKET}/"; aws s3 ls "s3://${BUCKET}/"
