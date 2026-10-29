**Tuần 2 (26/10–01/11/2026) Lê Huỳnh Như (24139035) – 8.25 giờ:**
- Tìm hiểu quy trình vận hành cụm Amazon EMR (cấu hình Primary/Core node, các cơ chế nộp Spark Step execution) và thiết lập môi trường Managed Service.
- Họp thống nhất giao thức benchmark với Đỗ Minh Hiển (0.75 giờ - làm chung): chốt phương án đo benchmark cùng job (WordCount, Aggregation), cùng dataset (1GB, 3GB, 5GB), mỗi mức chạy 3 lần lấy trung bình thời gian execution time; phân tích khác biệt cấu hình phần cứng (Self-Managed dùng 3 node t3.medium: 2 vCPU, 4 GiB RAM; EMR dùng 3 node m4.large: 2 vCPU, 8 GiB RAM); Như chủ trì soạn file quy hoạch benchmark/plan.md và file mẫu benchmark/results.csv, benchmark/results-self-managed.csv trên Git.
- Khởi tạo cụm Amazon EMR bằng giao diện AWS Management Console (Account ID 9337-3325-7957, Region us-east-1, ngày 28/10/2026 - 5.0 giờ):
  - Cấu hình cụm: chọn EMR Release emr-6.10.x, cài đặt các ứng dụng Hadoop 3.3.3, Spark 3.3.0, Zeppelin.
  - Cấu hình phần cứng Topology: 1 Primary node + 2 Core nodes loại m4.large (mỗi node 2 vCPU, 8 GiB RAM, 32 GB EBS storage).
  - Phân quyền IAM: chọn Service role EMR_DefaultRole và EC2 instance profile EMR_EC2_LabRole (roles có sẵn trong phiên AWS Learner Lab).
  - Chọn Key Pair vockey có sẵn để kết nối SSH.
  - Cấu hình Log & Tiết kiệm chi phí: bật tính năng ghi log tự động ra S3 (s3://hadoop-spark-lab-24139035/logs/), gắn nhãn tài nguyên (Project=HadoopSpark-EC2-vs-EMR, Owner=24139035), và bật tính năng Auto-termination (tự động xóa cụm khi ở trạng thái idle/rảnh quá thời gian quy định).
  - Nộp trực tiếp 2 Spark Steps mẫu (jobs/wordcount.py và jobs/aggregation.py) từ S3 thông qua giao diện EMR Console; kiểm tra các Step báo SUCCESS; xác nhận dữ liệu đầu ra đã được ghi thành công vào thư mục s3://hadoop-spark-lab-24139035/results/emr/.
  - Tiến hành Terminate cụm chủ động sau khi hoàn tất kiểm thử.
- Viết script AWS CLI tự động hóa tạo cụm EMR và chạy tự động (2.5 giờ):
  - Viết script infra/emr-create.sh: tự động gọi lệnh aws emr create-cluster với đầy đủ tham số (release emr-6.10.x, 3 node m4.large, cấu hình S3 log URI, gán IAM Roles, gán Tag).
  - Tích hợp tính năng tự động submit Spark Steps trực tiếp khi khởi tạo cụm và truyền tham số --auto-terminate để cụm tự động giải phóng tài nguyên ngay khi hoàn thành bài chạy, tránh phát sinh chi phí ngoài ý muốn.
  - Viết script tự động chạy đo benchmark benchmark/run-emr-benchmark-Nhu.sh và tổng hợp báo cáo kết quả benchmark/summary-emr.md.
  - Chạy thử nghiệm script infra/emr-create.sh thành công trên AWS CloudShell, nhận về Cluster ID và xác nhận cụm tự tạo, tự chạy job và tự xóa hoàn toàn tự động.
- Minh chứng:
  - Tài liệu benchmark: benchmark/plan.md, benchmark/results.csv, benchmark/results-self-managed.csv, benchmark/run-emr-benchmark-Nhu.sh, benchmark/summary-emr.md.
  - Script tự động: infra/emr-create.sh trên Git.
  - Hình ảnh lưu trong docs/evidence/w2/: emr-cluster.png (ảnh khởi tạo cụm EMR trên Console), emr-console-steps-completed.png (ảnh danh sách Steps chạy thành công), emr-console-results-success.png (ảnh kết quả tạo ra trong folder results/emr/), emr-tags.png (ảnh kiểm tra Tags cụm EMR), emr-cli-create-cluster.png (ảnh chạy lệnh tạo cụm bằng AWS CLI), emr-cli-output-success.png (ảnh kết quả chạy script CLI thành công).
- Khó khăn gặp phải và giải pháp:
  - (1) Lỗi permission khi tạo cụm EMR do tự tạo IAM Role mới. Giải pháp: Môi trường AWS Learner Lab không cho phép tạo Role mới, phải chọn chính xác 2 Role đã tạo sẵn là EMR_DefaultRole cho Service role và EMR_EC2_LabRole cho EC2 instance profile.
  - (2) Cụm EMR bị treo ở trạng thái WAITING gây tốn ngân sách Lab nếu quên xóa. Giải pháp: Bổ sung cờ --auto-terminate vào câu lệnh AWS CLI để đảm bảo cụm tự động xóa ngay sau khi thực hiện xong tất cả các Steps.
Kế hoạch tuần sau (Như): Tiến hành chạy thực nghiệm benchmark chính thức 3 lần cho cả 2 jobs (WordCount, Aggregation) trên 3 mức dữ liệu (1GB, 3GB, 5GB) trên cụm EMR. Ghi lại chính xác execution time vào file benchmark/results.csv, so sánh hiệu năng, số bước thao tác và chi phí vận hành với nhánh Self-Managed của Hiển để hoàn thiện báo cáo tổng kết.
Phần có AI hỗ trợ (Như):
- Công cụ / model: Claude (Claude 3.5 Sonnet).
- Prompt chính: "Sửa lỗi 'ClassNotFoundException: org.apache.hadoop.fs.s3a.S3AFileSystem' khi chạy spark-submit trên cụm Hadoop 3.3 tự dựng kết nối S3."
- Nội dung AI tạo: Hướng dẫn khai báo spark.jars.packages hoặc copy cặp file hadoop-aws.jar và aws-java-sdk-bundle.jar khớp phiên bản vào thư mục jars của Spark. Đoạn cấu hình spark-defaults.conf sử dụng fs.s3a.aws.credentials.provider=com.amazonaws.auth.InstanceProfileCredentialsProvider.
- Phần đã tự sửa/hoàn thiện: Cấu hình tự động nhận quyền từ LabInstanceProfile mà không cần điền thủ công AWS Access/Secret Key.
