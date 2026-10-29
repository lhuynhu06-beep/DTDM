#!/usr/bin/env bash
# =============================================================================
# — Tuần 4: Dọn dẹp tài nguyên nhánh EMR & Managed (Lê Huỳnh Như – 24139035)
#   ./infra/cleanup-nhu.sh           # Liệt kê tài nguyên SẼ xóa (dry-run)
#   ./infra/cleanup-nhu.sh --yes     # Xóa thật: EMR clusters, logs/data trên S3
# =============================================================================
set -uo pipefail
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}" AWS_PAGER=""

BUCKET="hadoop-spark-lab-24139035"
DO="${1:-}"

run() { 
  if [[ "$DO" == --yes ]]; then 
    echo "+ $*"; "$@"; 
  else 
    echo "[dry-run] $*"; 
  fi; 
}

echo "== 1. Terminate các cụm Amazon EMR đang chạy/chờ (Owner=24139035) =="
EMR_IDS=$(aws emr list-clusters --cluster-states WAITING RUNNING STARTING BOOTSTRAPPING \
  --query 'Clusters[].Id' --output text)

if [[ -n "$EMR_IDS" && "$EMR_IDS" != "None" ]]; then
  echo "Phát hiện EMR Clusters đang hoạt động: $EMR_IDS"
  # shellcheck disable=SC2086
  run aws emr terminate-clusters --cluster-ids $EMR_IDS
else
  echo "Không có EMR Cluster nào đang chạy."
fi

echo "== 2. Dọn dẹp dữ liệu tạm và logs trên S3 (${BUCKET}) =="
if aws s3 ls "s3://${BUCKET}" >/dev/null 2>&1; then
  echo "Xóa thư mục logs/ và data/ tạm trên S3..."
  run aws s3 rm "s3://${BUCKET}/logs/" --recursive --only-show-errors
  run aws s3 rm "s3://${BUCKET}/data/" --recursive --only-show-errors
  echo " GIỮ LẠI s3://${BUCKET}/results/ và s3://${BUCKET}/jobs/ để nộp báo cáo."
else
  echo "Bucket s3://${BUCKET} không tồn tại hoặc không có quyền truy cập."
fi

echo "== 3. Kiểm tra lại tài nguyên EMR còn lại =="
aws emr list-clusters --cluster-states TERMINATING TERMINATED \
  --query 'Clusters[0:5].[Id,Name,Status.State]' --output table
