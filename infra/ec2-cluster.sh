#!/usr/bin/env bash
# =============================================================================
# ec2-cluster.sh — Dựng / bật / tắt cụm Hadoop-Spark tự dựng (1 master + 2 worker)
# Nhánh Self-managed – Đỗ Minh Hiển (24139013)
#
# Chạy ở máy có AWS CLI v2 + credentials của Learner Lab (CloudShell hoặc laptop).
#
#   ./infra/ec2-cluster.sh up       # tạo SG + 3 EC2 (nếu chưa có) hoặc Start nếu đang Stop
#   ./infra/ec2-cluster.sh status   # liệt kê node, trạng thái, IP
#   ./infra/ec2-cluster.sh env      # ghi lại infra/cluster.env (IP public đổi sau mỗi lần Start)
#   ./infra/ec2-cluster.sh stop     # Stop cả 3 node (làm sau MỖI buổi)
#   ./infra/ec2-cluster.sh start    # Start lại cả 3 node
#
# Biến có thể ghi đè: MY_CIDR (mặc định = IP public hiện tại/32), INSTANCE_TYPE,
# VOLUME_GB, KEY_NAME, AZ, OPERATOR_PUBKEY (mặc định ~/.ssh/id_ed25519.pub — trên CloudShell
# tạo bằng: ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519).
#
# QUY ƯỚC NHÓM: báo Như trong nhóm chat TRƯỚC khi chạy `up`/`start`
# (không chạy song song với cụm EMR).
# =============================================================================
set -euo pipefail

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export AWS_PAGER=""

PROJECT="HadoopSpark-EC2-vs-EMR"
OWNER="24139013"
CLUSTER="hadoop-selfmanaged"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.medium}"
VOLUME_GB="${VOLUME_GB:-30}"
KEY_NAME="${KEY_NAME:-vockey}"
PROFILE="LabInstanceProfile"
OPERATOR_PUBKEY="${OPERATOR_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
AZ="${AZ:-us-east-1a}"            # t3 không có ở us-east-1e
SG_NAME="${CLUSTER}-sg"
NODES=(hadoop-master hadoop-worker1 hadoop-worker2)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/cluster.env"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }

tags_for() { # $1 = Name, $2 = Role
  echo "{Key=Name,Value=$1},{Key=Project,Value=${PROJECT}},{Key=Owner,Value=${OWNER}},{Key=Cluster,Value=${CLUSTER}},{Key=Role,Value=$2}"
}

# ---------- tra cứu -----------------------------------------------------------
default_vpc() {
  aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
    --query 'Vpcs[0].VpcId' --output text
}

subnet_in_az() {
  aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$1" "Name=availability-zone,Values=${AZ}" \
    --query 'Subnets[0].SubnetId' --output text
}

latest_al2023_ami() {
  aws ec2 describe-images --owners amazon \
    --filters 'Name=name,Values=al2023-ami-2023.*-kernel-*-x86_64' \
              'Name=state,Values=available' 'Name=architecture,Values=x86_64' \
    --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text
}

# instance-id của node theo tên (bỏ qua instance đã terminated)
instance_id() {
  aws ec2 describe-instances \
    --filters "Name=tag:Cluster,Values=${CLUSTER}" "Name=tag:Name,Values=$1" \
              'Name=instance-state-name,Values=pending,running,stopping,stopped' \
    --query 'Reservations[].Instances[0].InstanceId' --output text | awk '{print $1}'
}

all_ids() {
  aws ec2 describe-instances \
    --filters "Name=tag:Cluster,Values=${CLUSTER}" \
              'Name=instance-state-name,Values=pending,running,stopping,stopped' \
    --query 'Reservations[].Instances[].InstanceId' --output text
}

# ---------- Security Group ----------------------------------------------------
ensure_sg() {
  local vpc="$1" sg my_cidr
  sg=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=${vpc}" "Name=group-name,Values=${SG_NAME}" \
        --query 'SecurityGroups[0].GroupId' --output text)
  if [[ "$sg" == "None" || -z "$sg" ]]; then
    sg=$(aws ec2 create-security-group --vpc-id "$vpc" --group-name "$SG_NAME" \
          --description "Self-managed Hadoop/Spark cluster (${OWNER})" \
          --tag-specifications "ResourceType=security-group,Tags=[$(tags_for "$SG_NAME" sg)]" \
          --query GroupId --output text)
    log "Đã tạo Security Group ${sg}"
    # Cổng nội bộ (HDFS 9000/9866/9870, YARN 8030-8088, Spark…) chỉ mở cho chính SG
    aws ec2 authorize-security-group-ingress --group-id "$sg" \
      --ip-permissions "IpProtocol=-1,UserIdGroupPairs=[{GroupId=${sg},Description=intra-cluster}]" >/dev/null
  fi
  # SSH chỉ từ IP của người chạy script (UI xem qua SSH tunnel, không mở 9870/8088 ra Internet)
  my_cidr="${MY_CIDR:-$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')/32}"
  if aws ec2 authorize-security-group-ingress --group-id "$sg" \
       --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=${my_cidr},Description=ssh-${OWNER}}]" \
       >/dev/null 2>&1; then
    log "Mở SSH cho ${my_cidr}"
  else
    log "SSH cho ${my_cidr} đã có sẵn"
  fi
  echo "$sg"
}

# ---------- lệnh --------------------------------------------------------------
cmd_up() {
  local vpc subnet sg ami id role
  vpc=$(default_vpc);        [[ "$vpc" != "None" ]] || { log "Không tìm thấy default VPC"; exit 1; }
  subnet=$(subnet_in_az "$vpc")
  sg=$(ensure_sg "$vpc")
  ami=$(latest_al2023_ami)
  log "VPC=${vpc} Subnet=${subnet} (${AZ}) SG=${sg} AMI=${ami}"

  # Public key của máy điều khiển (vd. CloudShell) được thêm vào ec2-user qua user-data,
  # để SSH được mà không cần chép labsuser.pem lên CloudShell. Public key không phải bí mật.
  local ud; ud=$(mktemp)
  printf '#!/bin/bash\n' > "$ud"
  if [[ -f "$OPERATOR_PUBKEY" ]]; then
    printf "install -d -m700 -o ec2-user -g ec2-user /home/ec2-user/.ssh\necho '%s' >> /home/ec2-user/.ssh/authorized_keys\nchown ec2-user: /home/ec2-user/.ssh/authorized_keys; chmod 600 /home/ec2-user/.ssh/authorized_keys\n" \
      "$(cat "$OPERATOR_PUBKEY")" >> "$ud"
    log "Thêm ${OPERATOR_PUBKEY} vào authorized_keys qua user-data"
  fi

  for name in "${NODES[@]}"; do
    id=$(instance_id "$name")
    if [[ -n "$id" && "$id" != "None" ]]; then
      log "${name} đã tồn tại (${id}) → start nếu đang stopped"
      aws ec2 start-instances --instance-ids "$id" >/dev/null || true
      continue
    fi
    [[ "$name" == hadoop-master ]] && role=master || role=worker
    id=$(aws ec2 run-instances \
          --image-id "$ami" --instance-type "$INSTANCE_TYPE" --count 1 \
          --key-name "$KEY_NAME" --subnet-id "$subnet" --security-group-ids "$sg" \
          --associate-public-ip-address \
          --iam-instance-profile "Name=${PROFILE}" \
          --metadata-options 'HttpTokens=required,HttpEndpoint=enabled' \
          --user-data "file://${ud}" \
          --block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=${VOLUME_GB},VolumeType=gp3,DeleteOnTermination=true}" \
          --tag-specifications \
              "ResourceType=instance,Tags=[$(tags_for "$name" "$role")]" \
              "ResourceType=volume,Tags=[$(tags_for "${name}-root" "$role")]" \
          --query 'Instances[0].InstanceId' --output text)
    log "Đã tạo ${name}: ${id}"
  done

  # shellcheck disable=SC2046
  aws ec2 wait instance-running --instance-ids $(all_ids)
  cmd_env
  cmd_status
}

cmd_status() {
  aws ec2 describe-instances \
    --filters "Name=tag:Cluster,Values=${CLUSTER}" \
              'Name=instance-state-name,Values=pending,running,stopping,stopped' \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,InstanceType,State.Name,PrivateIpAddress,PublicIpAddress]' \
    --output table
}

# Ghi cluster.env: private IP (cố định) + public IP (đổi sau mỗi lần Start)
cmd_env() {
  local out="" name id priv pub
  for name in "${NODES[@]}"; do
    id=$(instance_id "$name")
    read -r priv pub < <(aws ec2 describe-instances --instance-ids "$id" \
      --query 'Reservations[0].Instances[0].[PrivateIpAddress,PublicIpAddress]' --output text)
    local var; var=$(echo "${name#hadoop-}" | tr '[:lower:]' '[:upper:]')
    out+="${var}_ID=${id}"$'\n'"${var}_IP=${priv}"$'\n'"${var}_PUBLIC_IP=${pub}"$'\n'
  done
  printf '# Sinh tự động bởi ec2-cluster.sh lúc %s — KHÔNG commit public IP nếu không cần\n%s' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$out" > "$ENV_FILE"
  log "Đã ghi ${ENV_FILE}"
}

cmd_stop() {
  local ids; ids=$(all_ids)
  [[ -n "$ids" ]] || { log "Không có node nào"; return; }
  # shellcheck disable=SC2086
  aws ec2 stop-instances --instance-ids $ids >/dev/null
  log "Đang Stop: ${ids}"
  # shellcheck disable=SC2086
  aws ec2 wait instance-stopped --instance-ids $ids
  cmd_status
}

cmd_start() {
  local ids; ids=$(all_ids)
  # shellcheck disable=SC2086
  aws ec2 start-instances --instance-ids $ids >/dev/null
  # shellcheck disable=SC2086
  aws ec2 wait instance-running --instance-ids $ids
  cmd_env
  cmd_status
}

case "${1:-}" in
  up)     cmd_up ;;
  status) cmd_status ;;
  env)    cmd_env ;;
  stop)   cmd_stop ;;
  start)  cmd_start ;;
  *) echo "Usage: $0 {up|status|env|stop|start}" >&2; exit 2 ;;
esac
