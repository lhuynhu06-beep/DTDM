**Tuần 1 (19/10–25/10/2026)**
**Đỗ Minh Hiển (24139013) – … giờ:**
- Tìm hiểu kiến trúc Hadoop 3 (HDFS: NameNode/SecondaryNameNode/DataNode; YARN: ResourceManager/NodeManager/ApplicationMaster) và Spark-on-YARN (client và cluster mode, S3A).
- Thiết kế cụm tự dựng: 1 master + 2 worker t3.medium, default VPC, subnet us-east-1a, Security Group (chỉ mở SSH từ IP nhóm, cổng nội bộ chỉ trong SG), EBS gp3 30 GB/node, LabInstanceProfile, tag theo quy ước. Lập ngân sách bộ nhớ YARN/Spark cho máy 4 GiB.
- Vẽ sơ đồ kiến trúc self-managed (draw.io + PNG).
- Viết script dựng cụm: `infra/ec2-cluster.sh` (up/start/stop/status bằng AWS CLI), `scripts/setup-base.sh` (hostname, /etc/hosts theo private IP, Java 11, Hadoop 3.3.6, Spark 3.5.5, SSH), `scripts/bootstrap-cluster.sh` (cài song song 3 node + SSH không mật khẩu).
- Khởi tạo cụm trên Learner Lab (Account 2111-2549-0692, us-east-1, 25/10/2026, chạy từ AWS CloudShell). Dựng được bằng 2 lệnh:
  - `ec2-cluster.sh up`: tạo SG `hadoop-selfmanaged-sg` và 3 node t3.medium ở us-east-1a, gắn đủ tag Project/Owner/Cluster/Role, dùng LabInstanceProfile. Mất khoảng 40 giây đến khi cả 3 node running.
    - hadoop-master: 172.31.11.100
    - hadoop-worker1: 172.31.12.128
    - hadoop-worker2: 172.31.8.218
  - `bootstrap-cluster.sh`: cài nền song song trên 3 node, mất **1 phút 44 giây**.
- Kết quả kiểm tra trên cả 3 node: OpenJDK 11.0.33, Hadoop 3.3.6, Spark 3.5.5, `/etc/hosts` dùng private IP. Master SSH không mật khẩu được tới hadoop-master, worker1, worker2 và localhost. Sau đó đã Stop cả 3 node (tổng thời gian chạy khoảng 6 phút).
- Minh chứng: `docs/architecture-self-managed.md`, `docs/diagrams/`, `infra/ec2-cluster.sh`, `scripts/setup-base.sh` trên Git. Ảnh chụp trong `docs/evidence/w1/`: CloudShell dựng cụm, kiểm tra phiên bản và /etc/hosts, EC2 console kèm tag/Account ID/Region, cụm đã Stop.
- Khó khăn:
  - (1) Terminal tích hợp trong trang Learner Lab chạy bằng role `runserver`, không có quyền EC2 (`UnauthorizedOperation` khi gọi DescribeVpcs). Đã chuyển sang AWS CloudShell, nơi dùng đúng quyền voclabs của phiên lab.
  - (2) Từ tài khoản của Hiển, lệnh `aws s3 ls s3://hadoop-spark-lab-24139035` trả về `NoSuchBucket`, tức bucket này hiện không tồn tại. Cần Như kiểm tra lại tên bucket hoặc tạo lại. Nếu hai bạn dùng hai tài khoản riêng thì cụm EC2 cần bucket policy cross-account hoặc một bucket riêng.
  - (3) Chọn Spark bản without-hadoop để S3A khớp phiên bản với Hadoop 3.3.6.

**Kế hoạch tuần sau (Hiển):** cấu hình HDFS/YARN (core-site, hdfs-site, yarn-site, mapred-site, workers), format NameNode, chạy Spark trên YARN, thêm S3A (hadoop-aws 3.3.6), chạy WordCount từ S3 và ghi vào `results/self-managed/`, viết `install-hadoop.sh`, `install-spark.sh`, `start/stop-cluster.sh`.

**Phần có AI hỗ trợ (Hiển):**
- Công cụ / model: Claude (Anthropic), model claude-opus-5-5.
- Prompt chính: "Đọc file phân công và repo, giúp tôi làm nhiệm vụ Tuần 1 nhánh tự dựng (thiết kế cụm, sơ đồ, script setup-base và dựng 3 EC2)".
- Nội dung AI tạo: bản nháp ghi chú kiến trúc, script sinh sơ đồ, `ec2-cluster.sh`, `setup-base.sh`, `bootstrap-cluster.sh`.
- Phần đã tự sửa/kiểm tra: …(điền: đã đọc lại từng cấu hình, chạy thử trên Learner Lab, chỉnh …)…
