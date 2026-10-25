**Tuần 1 (19/10–25/10/2026)**
**Đỗ Minh Hiển (24139013) – … giờ:**
- Tìm hiểu kiến trúc Hadoop 3 (HDFS: NameNode/SecondaryNameNode/DataNode; YARN: ResourceManager/NodeManager/ApplicationMaster) và Spark-on-YARN (client và cluster mode, S3A).
- Thiết kế cụm tự dựng: 1 master + 2 worker t3.medium, default VPC, subnet us-east-1a, Security Group (chỉ mở SSH từ IP nhóm, cổng nội bộ chỉ trong SG), EBS gp3 30 GB/node, LabInstanceProfile, tag theo quy ước. Lập ngân sách bộ nhớ YARN/Spark cho máy 4 GiB.
- Vẽ sơ đồ kiến trúc self-managed (draw.io + PNG).
- Viết script dựng cụm: `infra/ec2-cluster.sh` (up/start/stop/status bằng AWS CLI), `scripts/setup-base.sh` (hostname, /etc/hosts theo private IP, Java 11, Hadoop 3.3.6, Spark 3.5.5, SSH), `scripts/bootstrap-cluster.sh` (cài song song 3 node + SSH không mật khẩu).
- Khởi tạo 3 EC2 và chạy setup-base.sh: …(điền kết quả + ảnh console có Account ID/Region/thời gian)…
- Minh chứng: `docs/architecture-self-managed.md`, `docs/diagrams/`, `infra/ec2-cluster.sh`, `scripts/setup-base.sh` trên Git; ảnh EC2 console.
- Khó khăn: bucket S3 của nhóm nằm trong tài khoản Learner Lab của Như, nên cụm EC2 bên tài khoản của Hiển cần bucket policy cross-account (hoặc dùng bucket riêng). Chọn Spark bản without-hadoop để S3A khớp phiên bản Hadoop 3.3.6.

**Kế hoạch tuần sau (Hiển):** cấu hình HDFS/YARN (core-site, hdfs-site, yarn-site, mapred-site, workers), format NameNode, chạy Spark trên YARN, thêm S3A (hadoop-aws 3.3.6), chạy WordCount từ S3 và ghi vào `results/self-managed/`, viết `install-hadoop.sh`, `install-spark.sh`, `start/stop-cluster.sh`.

**Phần có AI hỗ trợ (Hiển):**
- Công cụ / model: Claude (Anthropic), model claude-opus-5-5.
- Prompt chính: "Đọc file phân công và repo, giúp tôi làm nhiệm vụ Tuần 1 nhánh tự dựng (thiết kế cụm, sơ đồ, script setup-base và dựng 3 EC2)".
- Nội dung AI tạo: bản nháp ghi chú kiến trúc, script sinh sơ đồ, `ec2-cluster.sh`, `setup-base.sh`, `bootstrap-cluster.sh`.
- Phần đã tự sửa/kiểm tra: …(điền: đã đọc lại từng cấu hình, chạy thử trên Learner Lab, chỉnh …)…
