# Kịch bản quay demo: phần cụm tự dựng (khoảng 4 phút, nằm trong video tổng ≤ 10 phút)

Người trình bày: Đỗ Minh Hiển (24139013). Quay màn hình bằng QuickTime (macOS: ⌘⇧5 → *Record Selected Portion*).
Trước khi quay:
1. Start Lab, mở CloudShell, chạy `cd ~/DTDM && source infra/cluster.env`.
2. Bật lại cụm CloudFormation: `aws ec2 start-instances` cho các instance có tag `Cluster=hadoop-cfn`.
3. Thêm IP mới của CloudShell vào SG bằng cách deploy lại stack với `SshCidr=$(curl -s https://checkip.amazonaws.com)/32`.
4. Chạy `ssh ec2-user@<master> bash ~/DTDM/scripts/start-cluster.sh`. Sau khi Stop/Start, HDFS và YARN không tự khởi động lại.

| # | Thời lượng | Màn hình | Thao tác / lệnh | Lời thoại gợi ý |
|---|---|---|---|---|
| 1 | 0:20 | Sơ đồ `self-managed-architecture.png` | (không gõ lệnh) | "Cụm tự dựng gồm 1 master và 2 worker t3.medium trong 1 subnet. Security Group chỉ mở SSH, còn S3A dùng quyền của LabInstanceProfile." |
| 2 | 0:40 | CloudShell | `aws cloudformation describe-stacks --stack-name hadoop-cfn --query 'Stacks[0].[StackStatus,Outputs]'` | "Toàn bộ hạ tầng dựng bằng 1 lệnh CloudFormation. Stack chỉ báo CREATE_COMPLETE khi master đã xác nhận có 2 DataNode." |
| 3 | 0:40 | CloudShell → master | `ssh ec2-user@$MASTER_PUBLIC_IP` rồi `jps; hdfs dfsadmin -report \| head -20; yarn node -list` | "NameNode và ResourceManager chạy trên master. Mỗi worker có DataNode và NodeManager." |
| 4 | 0:40 | Trình duyệt qua SSH tunnel | `ssh -N -L 9870:…:9870 -L 8088:…:8088 -L 18080:…:18080 …` rồi mở `localhost:9870`, `:8088` | "Các cổng web không mở ra Internet, chỉ xem được qua tunnel." |
| 5 | 1:00 | master | `spark-submit --deploy-mode cluster ~/DTDM/jobs/wordcount.py s3a://$BUCKET/data/text/1g/ s3a://$BUCKET/results/self-managed/demo-$(date +%s)` | "Chạy WordCount 1 GB đọc thẳng từ S3. Kết quả ghi lại về S3." |
| 6 | 0:30 | CloudWatch dashboard | mở `HadoopSelfManaged-hadoop-selfmanaged` | "Đây là CPU, RAM, disk và CPU credit của 3 node trong lúc chạy job, cùng 2 alarm." |
| 7 | 0:30 | `benchmark/summary-self-managed.md` | (không gõ lệnh) | "Thời gian trung bình 3 lần chạy cho mỗi mức dữ liệu, và bảng trước/sau khi tối ưu Spark." |

Quay xong: `./infra/ec2-cluster.sh stop` và End Lab. Chỉ xoá stack (`./infra/cleanup.sh --yes`) sau khi nhóm đã nộp bài.
