**Tuần 3 (02/11–08/11/2026)**: phần của Đỗ Minh Hiển (24139013)
*(Ghi chú trung thực: phần kỹ thuật được làm sớm vào ngày 25/10/2026 trên Learner Lab, Account 2111-2549-0692, us-east-1.)*

**Đỗ Minh Hiển (24139013) – … giờ:**
- **CloudFormation** `infra/self-managed.yaml`: dựng cả cụm bằng 1 lệnh `aws cloudformation deploy`.
  - Thành phần: VPC 10.30.0.0/16, public subnet us-east-1a, IGW, route table, S3 Gateway Endpoint, Security Group (SSH chỉ từ `SshCidr`, cổng nội bộ chỉ trong SG), 3 EC2 với private IP cố định, `LabInstanceProfile`, IMDSv2, gp3 30 GB và đủ tag.
  - User-data tải gói mã nguồn từ S3, rồi chạy `setup-base.sh` → `install-hadoop.sh` → `install-spark.sh` → CloudWatch Agent.
  - Master công bố public key SSH qua S3 cho worker. Master chỉ gửi `cfn-signal` sau khi kiểm tra có đúng 2 DataNode (`CreationPolicy` 30 phút).
  - Kết quả: stack `hadoop-cfn` **CREATE_COMPLETE trong 4 phút 37 giây**, 13 tài nguyên. Kiểm tra trên cụm mới: Live datanodes (2), 2 NodeManager RUNNING.
  - Đã kiểm tra bằng `cfn-lint`.
- **Lỗi phát hiện nhờ IaC:** lần dựng đầu, worker2 cài Java thất bại ("Unable to find a match: java-11-amazon-corretto-devel") vì metadata dnf chưa sẵn sàng lúc máy vừa boot. Master chờ SSH tới worker2 không được nên stack không hoàn tất. Đã thêm vòng thử lại 5 lần (`dnf clean metadata` giữa các lần) vào `setup-base.sh`, xoá stack và dựng lại thành công.
- **Bảo mật:**
  - Security Group chỉ có 2 rule inbound: TCP 22 từ IP của máy điều khiển /32, và All từ chính SG.
  - Không mở cổng web nào ra Internet; xem giao diện qua SSH tunnel.
  - Chỉ dùng LabRole/LabInstanceProfile; IMDSv2 bắt buộc; không có access key nào nằm trên máy.
  - Bucket bật Block Public Access (cả 4 mục) và mã hoá SSE-S3.
- **Giám sát:**
  - CloudWatch Agent chạy trên 3 node, đẩy RAM, disk, CPU và swap vào namespace `HadoopSelfManaged`.
  - Dashboard `HadoopSelfManaged-hadoop-selfmanaged` gồm CPU, RAM, Disk, CPUCreditBalance và Network.
  - 2 alarm: RAM worker1 > 90% trong 3 phút; CPU master > 85% trong 5 phút.
  - Nhận xét từ dashboard: **CPUCreditBalance của 2 worker về 0** ngay sau vài phút đầu chạy tải và giữ ở 0 suốt benchmark. Instance chạy ở chế độ *unlimited* nên không bị bóp CPU, nhưng bị tính phí credit vượt. Khi so với m4.large phải tính đến điểm này.
- **Benchmark cụm tự dựng:**
  - Chạy theo plan: 3 mức dữ liệu × 3 lần × 2 job, `--deploy-mode cluster`.
  - Để kịp thời gian phiên lab, 2 cụm **giống hệt nhau** (cùng loại máy, cùng cấu hình, cùng script) chạy song song: cụm dựng bằng script chạy WordCount 1 GB và 3 GB, cùng phần tối ưu; cụm CloudFormation chạy aggregation 1/3/5 GB và WordCount 5 GB. Mỗi cụm chỉ chạy 1 job tại một thời điểm.
  - Kết quả (trung bình 3 lần):
    - WordCount: 1 GB **227,4 s**, 3 GB **577,4 s**, 5 GB **943,2 s**.
    - Aggregation: 1 GB **118,4 s**, 3 GB **206,6 s**, 5 GB **285,7 s**.
    - Hệ số biến thiên dưới 6%.
    - Chi tiết: `benchmark/summary-self-managed.md`, `benchmark/runtime-self-managed.png`.
  - Có 1 lần chạy bị loại (413 s, do chạy chồng với một job còn sót), ghi lại trong `results-excluded.csv`.
- **Minh chứng:** `docs/evidence/w3/` (stack resources, SG inbound, S3 Block Public Access, CloudWatch dashboard, cụm CFN sau khi dựng).
- **Đổi chéo với Như:** *(chưa làm; cần script EMR của Như)*

**Phần có AI hỗ trợ:** Claude (Anthropic), claude-opus-5-5.
- AI tạo: template CloudFormation, cấu hình CloudWatch Agent, script dashboard/alarm, script benchmark.
- Hiển tự kiểm tra: … *(điền)*
