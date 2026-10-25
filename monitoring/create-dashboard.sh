#!/usr/bin/env bash
# =============================================================================
# create-dashboard.sh — Dashboard + alarm CloudWatch cho cụm tự dựng (chạy ở CloudShell). Đỗ Minh Hiển (24139013)
#   ./monitoring/create-dashboard.sh            # đọc instance-id từ infra/cluster.env
#   STACK=hadoop-cfn ./monitoring/create-dashboard.sh   # hoặc lấy theo tag Cluster của stack CloudFormation
# =============================================================================
set -euo pipefail
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}" AWS_PAGER=""
CLUSTER="${CLUSTER:-hadoop-selfmanaged}"
NAME="${NAME:-HadoopSelfManaged-${CLUSTER}}"
mapfile -t ROWS < <(aws ec2 describe-instances \
  --filters "Name=tag:Cluster,Values=${CLUSTER}" 'Name=instance-state-name,Values=pending,running,stopped' \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId]' --output text | sort)
(( ${#ROWS[@]} > 0 )) || { echo "Không tìm thấy node của ${CLUSTER}" >&2; exit 1; }

python3 - "$NAME" "$AWS_DEFAULT_REGION" "${ROWS[@]}" > /tmp/dashboard.json <<'PY'
import json, sys
name, region, rows = sys.argv[1], sys.argv[2], [r.split() for r in sys.argv[3:]]
def w(title, metrics, x, y, unit=None):
    p = {"title": title, "region": region, "metrics": metrics, "view": "timeSeries",
         "stat": "Average", "period": 60}
    if unit: p["yAxis"] = {"left": {"min": 0, "max": 100, "label": unit}}
    return {"type": "metric", "x": x, "y": y, "width": 12, "height": 6, "properties": p}
cpu  = [["AWS/EC2", "CPUUtilization", "InstanceId", i, {"label": n}] for n, i in rows]
cred = [["AWS/EC2", "CPUCreditBalance", "InstanceId", i, {"label": n}] for n, i in rows]
mem  = [["HadoopSelfManaged", "mem_used_percent", "InstanceId", i, {"label": n}] for n, i in rows]
# disk có thêm dimension device/fstype/path tuỳ AMI → dùng SEARCH thay vì ghi cứng
dsk  = [[{"expression": "SEARCH('{HadoopSelfManaged,InstanceId,device,fstype,path} MetricName=\"disk_used_percent\" path=\"/\"', 'Average', 60)", "id": "d1"}]]
net  = [["AWS/EC2", "NetworkIn", "InstanceId", i, {"label": n + " in", "stat": "Sum"}] for n, i in rows]
body = {"widgets": [
    {"type": "text", "x": 0, "y": 0, "width": 24, "height": 2, "properties": {"markdown":
     f"## {name}\nCụm Hadoop/Spark tự dựng (1 master + 2 worker t3.medium) – Project=HadoopSpark-EC2-vs-EMR, Owner=24139013"}},
    w("CPU (%) – AWS/EC2", cpu, 0, 2, "%"), w("RAM used (%) – CloudWatch Agent", mem, 12, 2, "%"),
    w("Disk / used (%) – CloudWatch Agent", dsk, 0, 8, "%"), w("CPU credit balance (t3 burstable)", cred, 12, 8),
    w("Network in (bytes, sum/phút)", net, 0, 14)]}
print(json.dumps(body, ensure_ascii=False))
PY
aws cloudwatch put-dashboard --dashboard-name "$NAME" --dashboard-body file:///tmp/dashboard.json
echo "Dashboard: https://${AWS_DEFAULT_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_DEFAULT_REGION}#dashboards/dashboard/${NAME}"

# Alarm: RAM của hadoop-worker1 > 90% trong 3 phút liên tiếp (dấu hiệu container sắp bị OOM-kill)
W1=$(printf '%s\n' "${ROWS[@]}" | awk '$1=="hadoop-worker1"{print $2}')
aws cloudwatch put-metric-alarm --alarm-name "${CLUSTER}-worker1-mem-high" \
  --alarm-description "RAM hadoop-worker1 > 90% (3 phút) – cụm tự dựng 24139013" \
  --namespace HadoopSelfManaged --metric-name mem_used_percent --dimensions "Name=InstanceId,Value=${W1}" \
  --statistic Average --period 60 --evaluation-periods 3 --threshold 90 \
  --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --tags Key=Project,Value=HadoopSpark-EC2-vs-EMR Key=Owner,Value=24139013
# Alarm: CPU master > 85% trong 5 phút
M=$(printf '%s\n' "${ROWS[@]}" | awk '$1=="hadoop-master"{print $2}')
aws cloudwatch put-metric-alarm --alarm-name "${CLUSTER}-master-cpu-high" \
  --alarm-description "CPU hadoop-master > 85% (5 phút) – cụm tự dựng 24139013" \
  --namespace AWS/EC2 --metric-name CPUUtilization --dimensions "Name=InstanceId,Value=${M}" \
  --statistic Average --period 60 --evaluation-periods 5 --threshold 85 \
  --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --tags Key=Project,Value=HadoopSpark-EC2-vs-EMR Key=Owner,Value=24139013
aws cloudwatch describe-alarms --alarm-name-prefix "$CLUSTER" --query 'MetricAlarms[].[AlarmName,StateValue]' --output table
