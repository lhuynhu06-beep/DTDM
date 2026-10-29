Tuần 2 (26/10–01/11/2026) Lê Huỳnh Như (24139035) – 10.0 giờ:
- Tìm hiểu quy trình vận hành cụm Amazon EMR (cấu hình Primary/Core node, các cơ chế nộp Spark Step execution) và thiết lập môi trường Managed Service.
- Họp thống nhất giao thức benchmark với Đỗ Minh Hiển: chốt phương án đo benchmark cùng job (WordCount, Aggregation), cùng dataset (1GB, 3GB, 5GB), mỗi mức chạy 3 lần lấy trung bình thời gian execution time; phân tích khác biệt cấu hình phần cứng (Self-Managed dùng 3 node t3.medium: 2 vCPU, 4 GiB RAM; EMR dùng 3 node m4.large: 2 vCPU, 8 GiB RAM); Như chủ trì soạn file quy hoạch benchmark/plan.md và file mẫu benchmark/results.csv, benchmark/results-self-managed.csv trên Git.
- Khởi tạo cụm Amazon EMR bằng giao diện AWS Management Console (Account ID 9337-3325-7957, Region us-east-1, ngày 28/10/2026):
  - Cấu hình cụm: chọn EMR Release emr-6.10.x, cài đặt các ứng dụng Hadoop 3.3.3, Spark 3.3.0, Zeppelin.
  - Cấu hình phần cứng Topology: 1 Primary node + 2 Core nodes loại m4.large (mỗi node 2 vCPU, 8 GiB RAM, 32 GB EBS storage).
  - Phân quyền IAM: chọn Service role EMR_DefaultRole và EC2 instance profile EMR_EC2_LabRole (roles có sẵn trong phiên AWS Learner Lab).
  - Chọn Key Pair vockey có sẵn để kết nối SSH.
  - Cấu hình Log & Tiết kiệm chi phí: bật tính năng ghi log tự động ra S3 (s3://hadoop-spark-lab-24139035/logs/), gắn nhãn tài nguyên (Project=HadoopSpark-EC2-vs-EMR, Owner=24139035), và bật tính năng Auto-termination (tự động xóa cụm khi ở trạng thái idle/rảnh quá thời gian quy định).
  - Nộp trực tiếp Spark Step xử lý tệp tin ChiPheo.txt và các PySpark Jobs (jobs/wordcount.py, jobs/aggregation.py) từ S3 thông qua giao diện EMR Console; kiểm tra các Step báo SUCCESS; xuất kết quả đếm từ thực tế về thư mục results/emr/ trên S3 và đồng bộ file part-00000 lên kho lưu trữ GitHub của nhóm.
  - Tiến hành Terminate cụm chủ động sau khi hoàn tất kiểm thử.
- Viết script AWS CLI tự động hóa tạo cụm EMR và chạy tự động (run-emr-benchmark-Nhu.sh / infra/emr-create.sh):
  - Upload file truyện văn học Việt Nam ChiPheo.txt vào phân vùng data/ và mã nguồn xử lý vào jobs/ trên Amazon S3 bucket hadoop-spark-lab-24139035.
  - Tích hợp tham số tự động hủy cụm khi nhàn rỗi (--auto-terminate) để tối ưu chi phí.
  - Thực thi kịch bản tạo cụm tự động hóa qua AWS CloudShell. Ghi nhận hệ thống chạy Step WordCount xử lý tệp tin ChiPheo.txt thành công xuất sắc trong vòng 50 giây.
  - Tự động chạy đo benchmark và tổng hợp báo cáo kết quả benchmark/summary-emr.md.
- Minh chứng:
  - Tài liệu benchmark: benchmark/plan.md, benchmark/results.csv, benchmark/results-self-managed.csv, benchmark/run-emr-benchmark-Nhu.sh, benchmark/summary-emr.md.
  - Script tự động: infra/emr-create.sh, benchmark/run-emr-benchmark-Nhu.sh trên Git.
  - Hình ảnh lưu trong docs/evidence/w2/: emr-cluster.png (ảnh khởi tạo cụm EMR trên Console), emr-console-steps-completed.png (ảnh danh sách Steps chạy thành công), emr-console-results-success.png (ảnh kết quả tạo ra trong folder results/emr/), emr-tags.png (ảnh kiểm tra Tags cụm EMR), emr-cli-create-cluster.png (ảnh chạy lệnh tạo cụm bằng AWS CLI), emr-cli-output-success.png (ảnh kết quả chạy script CLI thành công).
- Khó khăn gặp phải và giải pháp:
  - (1) Do chạy script liên tiếp dẫn đến hiện tượng quá tải vCPU Quotas (giới hạn 32 vCPU của Learner Lab) khiến các cụm sau bị báo lỗi Échec d'instance / Instance Launch Failed. Giải pháp: Khắc phục bằng cách chủ động giải phóng cụm lỗi và chuyển sang cơ chế chạy tuần tự.
  - (2) Lỗi permission khi tạo cụm EMR do tự tạo IAM Role mới. Giải pháp: Môi trường AWS Learner Lab không cho phép tạo Role mới, phải chọn chính xác 2 Role đã tạo sẵn là EMR_DefaultRole cho Service role và EMR_EC2_LabRole cho EC2 instance profile.
Kế hoạch tuần sau (Như): Phát triển thêm kịch bản kiểm thử cho tác vụ Data Aggregation, nâng mức tải tập tin lớn (1GB, 3GB, 5GB), theo dõi giám sát qua hệ thống giám sát CloudWatch và ghi lại chính xác thời gian chạy vào file benchmark/results.csv để so sánh với cụm Self-Managed của Hiển.
Phần có AI hỗ trợ (Như):
Phần có AI hỗ trợ (Như):
- Công cụ / model: Claude (Claude 3.5 Sonnet).
- Prompt chính: "Sửa lỗi 'ClassNotFoundException: org.apache.hadoop.fs.s3a.S3AFileSystem' khi chạy spark-submit trên cụm Hadoop 3.3 tự dựng kết nối S3."
- Nội dung AI tạo: Hướng dẫn khai báo spark.jars.packages hoặc copy cặp file hadoop-aws.jar và aws-java-sdk-bundle.jar khớp phiên bản vào thư mục jars của Spark. Đoạn cấu hình spark-defaults.conf sử dụng fs.s3a.aws.credentials.provider=com.amazonaws.auth.InstanceProfileCredentialsProvider.
- Phần đã tự sửa/hoàn thiện: Cấu hình tự động nhận quyền từ LabInstanceProfile mà không cần điền thủ công AWS Access/Secret Key.
