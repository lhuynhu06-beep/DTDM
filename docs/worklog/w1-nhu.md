**Tuần 1 (19/10–25/10/2026) Lê Huỳnh Như (24139035) – 8.0 giờ:**
- Tìm hiểu kiến trúc Amazon EMR (gồm node chính Primary quản lý và các node phụ Core xử lý dữ liệu) và dịch vụ lưu trữ Amazon S3 (cách tạo thư mục, cách kết nối PySpark với S3 qua S3A).
- Họp khởi động nhóm với Đỗ Minh Hiển (24139013): chốt dùng chung một vùng us-east-1 (dùng file vockey có sẵn), quy ước gắn nhãn bắt buộc trên mọi tài nguyên (Project=HadoopSpark-EC2-vs-EMR, Owner=24139035/24139013), thống nhất cây thư mục trên Git (infra/, scripts/, jobs/, benchmark/, docs/), và hẹn lịch không bao giờ bật đồng thời cụm EC2 và EMR để không bị vượt quá giới hạn tài khoản Student (tối đa 9 máy EC2 / 32 vCPUs).
- Khởi tạo Repository GitHub https://github.com/lhuynhu06-beep/DTDM và tự tạo S3 Bucket thủ công bằng giao diện web AWS Console (Account ID 9337-3325-7957, us-east-1, ngày 21/10/2026):
  - Nhấn nút Create bucket, đặt tên duy nhất: s3://hadoop-spark-lab-24139035.
  - Tích chọn Block All Public Access để khóa toàn bộ quyền truy cập công khai, tránh lộ dữ liệu.
  - Chọn bật mã hóa tự động SSE-S3 để bảo vệ file lưu trữ.
  - Gắn tag theo đúng quy ước nhóm: Project=HadoopSpark-EC2-vs-EMR và Owner=24139035.
  - Bấm Create folder tạo sẵn 4 thư mục chính: /data/ (chứa dữ liệu đầu vào), /jobs/ (chứa file code PySpark), /logs/ (chứa file log chạy EMR), /results/ (chứa kết quả đầu ra).
- Cấu hình phân quyền Cross-Account (infra/s3-bucket-policy.json): dán đoạn mã S3 Bucket Policy vào tab Permissions trên AWS Console để cấp quyền cho IAM Role LabRole (arn:aws:iam::202976464461:role/LabRole) thuộc tài khoản của Hiển (2111-2549-0692), giúp máy EC2 của Hiển có thể đọc và ghi file vào S3 của Như.
- Chuẩn bị dữ liệu và tải lên S3:
  - Thu thập các file văn bản và file CSV giao dịch bán hàng, tạo ra 3 bộ dữ liệu theo đúng 3 mức dung lượng yêu cầu: ~1 GB, ~3 GB và ~5 GB.
  - Dùng nút Upload trên trang web S3 Console và lệnh AWS CLI (aws s3 cp data/ s3://hadoop-spark-lab-24139035/data/ --recursive) để tải toàn bộ dữ liệu và file code lên S3.
- Lập trình 2 file PySpark và chạy thử trên máy cá nhân (Local Mode):
  - Viết jobs/wordcount.py: nhận đường dẫn file đầu vào và đầu ra, dùng lệnh regex \W+ để tách từng từ trong file văn bản, đếm số lần xuất hiện của từng từ và lưu kết quả lại.
  - Viết jobs/aggregation.py: đọc file CSV bán hàng, lấy cột Amount đổi sang kiểu số, gom nhóm theo danh mục mặt hàng (Category) để tính tổng doanh thu và đếm số lượng giao dịch.
  - Chạy thử cả 2 file bằng lệnh spark-submit --master local[*] trên máy cá nhân, xác nhận code chạy thành công, không bị lỗi cú pháp trước khi mang lên EMR.
- Minh chứng: docs/meeting-w1.md, infra/s3-bucket-policy.json, jobs/wordcount.py, jobs/aggregation.py trên Git. Ảnh lưu trong thư mục docs/evidence/w1/: bucketS3.png (ảnh tạo S3 trên Console), TagBucketS3.png (ảnh kiểm tra Tag và mã hóa), s3-data-chipheo.png (ảnh các file dữ liệu 1GB/3GB/5GB), s3-jobs-scripts.png (ảnh các file code PySpark đã up lên S3).
- Khó khăn gặp phải và giải pháp:
  - (1) Tài khoản của Hiển không đọc được S3 của Như do môi trường AWS Learner Lab tách riêng 2 tài khoản khác nhau. Giải pháp: Như đã viết file S3 Bucket Policy và dán lên S3 Console để cấp quyền cho Role LabRole bên tài khoản Hiển.
  - (2) Báo lỗi ClassNotFoundException: org.apache.hadoop.fs.s3a.S3AFileSystem khi test chạy PySpark đọc đường dẫn s3a:// ở local do thiếu thư viện kết nối. Giải pháp: Thêm tham số --packages org.apache.hadoop:hadoop-aws:3.3.6,com.amazonaws:aws-java-sdk-bundle:1.12.367 vào câu lệnh spark-submit.
Kế hoạch tuần sau (Như): Tạo cụm Amazon EMR (phiên bản emr-6.10.x gồm 1 máy Primary + 2 máy Core m4.large), viết script infra/emr-create.sh bằng AWS CLI để tự động tạo cụm và nộp bài chạy 2 file PySpark (wordcount.py, aggregation.py) từ S3, bật chế độ --auto-terminate để cụm tự tắt ngay khi chạy xong giúp tiết kiệm tiền Lab.
Phần có AI hỗ trợ (Như):
- Công cụ / model: Claude (Anthropic), model claude-3-5-sonnet.
- Prompt chính: "Đọc file phân công và repo, giúp tôi làm nhiệm vụ Tuần 1 nhánh Managed Service (tạo S3 bucket qua AWS Console, cấu hình bảo mật, chuẩn bị dataset 1GB/3GB/5GB, S3 policy Cross-Account và viết 2 script PySpark WordCount & Aggregation)".
- Nội dung AI tạo: bản nháp quy hoạch S3, khung mã nguồn jobs/wordcount.py, jobs/aggregation.py và file cấu hình JSON infra/s3-bucket-policy.json.
- Phần đã tự sửa/kiểm tra: tự thao tác tạo Bucket và cấu hình bảo mật trực tiếp trên AWS S3 Console, kiểm tra lại code PySpark, sửa lại cách tách từ tiếng Việt, khai báo lại Schema cho file CSV, test chạy thử local thành công, dán đúng mã ARN LabRole của Hiển vào S3 Policy và lưu policy thành công trên S3 Console.
