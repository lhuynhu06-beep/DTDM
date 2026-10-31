# KỊCH BẢN QUAY VIDEO DEMO ĐỒ ÁN (THAO TÁC MÀN HÌNH & THUYẾT MINH KỸ THUẬT)
**Đề tài:** Triển khai cụm Hadoop/Spark tự dựng trên EC2 và so sánh với Amazon EMR  
**Repository:** https://github.com/lhuynhu06-beep/DTDM  

---

## ⏱️ CẤU TRÚC THỜI LƯỢNG (~7-8 PHÚT)

| Phần | Nội dung chính | Thời lượng | Người thực hiện |
| :--- | :--- | :--- | :--- |
| **Phần 1** | Hạ tầng Amazon S3 & Phân quyền Cross-Account | 1:15 | Lê Huỳnh Như |
| **Phần 2** | Dựng cụm EC2 Self-Managed bằng CloudFormation | 2:15 | Đỗ Minh Hiển |
| **Phần 3** | Tự động hóa cụm Amazon EMR bằng AWS CLI | 2:15 | Lê Huỳnh Như |
| **Phần 4** | Giám sát CloudWatch Dashboard & Kết quả Benchmark | 1:30 | Cả hai |
| **Phần 5** | Dọn dẹp tài nguyên (Cleanup) & Chi phí | 0:45 | Lê Huỳnh Như |

---

## 🎬 NỘI DUNG KỊCH BẢN CHI TIẾT

### PHẦN 1: HẠ TẦNG AMAZON S3 & PHÂN QUYỀN (0:00 - 1:15)
* **Thao tác màn hình:**
  1. Mở trang chủ AWS Console, show rõ **Account ID** (9337-3325-7957) và Region **us-east-1** ở góc phải màn hình.
  2. Mở dịch vụ **Amazon S3**, truy cập bucket `s3://hadoop-spark-lab-24139035`.
  3. Mở tab **Permissions**: Show cấu hình **Block All Public Access** (Enabled) và dán file **S3 Bucket Policy** (`infra/s3-bucket-policy.json`) cấp quyền Cross-Account cho IAM Role `LabRole` của tài khoản Hiển (202976464461).
  4. Mở tab **Properties**: Show mã hóa tự động **SSE-S3** và hệ thống **Tags** (`Project=HadoopSpark-EC2-vs-EMR`, `Owner=24139035`).
  5. Mở danh sách thư mục: Show `/data/` (chứa các bộ dữ liệu 1GB, 3GB, 5GB, file *ChiPheo.txt*), `/jobs/` (`wordcount.py`, `aggregation.py`), `/logs/`, và `/results/`.

* **Lời thuyết minh:**
  > "Hạ tầng lưu trữ dùng chung được khởi tạo tại S3 Bucket `s3://hadoop-spark-lab-24139035` thuộc Region `us-east-1`. Toàn bộ dữ liệu được khóa truy cập công khai và mã hóa tự động SSE-S3. Phân quyền Cross-Account được thiết lập qua S3 Bucket Policy cho phép IAM Role `LabRole` của tài khoản thành viên đọc/ghi dữ liệu trực tiếp. Bộ dữ liệu đầu vào gồm 3 mức dung lượng 1GB, 3GB, 5GB và các mã nguồn PySpark đã sẵn sàng tại các đường dẫn quy định."

---

### PHẦN 2: TRIỂN KHAI CỤM EC2 SELF-MANAGED BẰNG CLOUDFORMATATION (1:15 - 3:30)
* **Thao tác màn hình:**
  1. Chuyển sang giao diện **AWS CloudFormation**, mở Stack `hadoop-cfn` báo trạng thái `CREATE_COMPLETE`. Show chi tiết thời gian khởi tạo hạ tầng là 4 phút 37 giây.
  2. Chuyển sang giao diện **EC2 Instances**: Show 3 máy chủ đang chạy (`master`, `worker1`, `worker2` loại `t3.medium`: 2 vCPU, 4 GiB RAM, EBS gp3 30GB) có gắn `LabInstanceProfile` và Tag `Owner=24139013`.
  3. Mở trình duyệt qua SSH Tunnel: Truy cập **NameNode Web UI (port 9870)** show 2 Live DataNodes và **YARN ResourceManager UI (port 8088)** show tổng số tài nguyên Memory/vCore quản lý.
  4. Mở Terminal: Thực thi câu lệnh `spark-submit` nộp job WordCount chạy trên YARN đọc dữ liệu qua connector `s3a://hadoop-spark-lab-24139035/data/`.
  5. Mở S3 Console: Show file kết quả được ghi thành công vào thư mục `s3://hadoop-spark-lab-24139035/results/self-managed/`.

* **Lời thuyết minh:**
  > "Nhánh Self-Managed được triển khai hoàn toàn tự động bằng Infrastructure as Code qua CloudFormation template `infra/self-managed.yaml`. Hệ thống tự động dựng VPC, Security Group và 3 EC2 node `t3.medium` trong 4 phút 37 giây. Cụm Hadoop 3.3 và Spark 3.5 được cấu hình chạy trên YARN, kết nối trực tiếp với S3 thông qua S3A Connector và tự động lấy quyền từ `LabInstanceProfile`. Kết quả thực thi job WordCount được ghi nhận thành công về thư mục chỉ định trên S3."

---

### PHẦN 3: TỰ ĐỘNG HÓA CỤM AMAZON EMR BẰNG AWS CLI (3:30 - 5:45)
* **Thao tác màn hình:**
  1. Mở **AWS CloudShell**, thực thi script `infra/emr-create.sh`. Show màn hình chạy lệnh `aws emr create-cluster` với các tham số release `emr-6.10.x`, 3 node `m4.large`, service role `EMR_DefaultRole`, instance profile `EMR_EC2_LabRole` và cờ `--auto-terminate`.
  2. Mở giao diện **Amazon EMR Console**: Show cụm EMR được tạo chuyển từ `STARTING` sang `RUNNING`.
  3. Mở tab **Steps**: Show danh sách 2 Spark Steps (`WordCount`, `Aggregation`) nộp từ S3 chuyển trạng thái sang `COMPLETED` (xử lý Step *ChiPheo.txt* thành công trong 50 giây).
  4. Mở S3 Console: Show thư mục `s3://hadoop-spark-lab-24139035/results/emr/` có file đánh dấu `_SUCCESS` và file kết quả `part-00000`. Cụm EMR tự động giải phóng tài nguyên về trạng thái `TERMINATED`.

* **Lời thuyết minh:**
  > "Nhánh Managed Service được tự động hóa bằng AWS CLI qua script `infra/emr-create.sh`. Lệnh khởi tạo cụm EMR release `emr-6.10.x` gồm 1 Primary node và 2 Core node `m4.large`, tự động gán các IAM Role có sẵn trong Learner Lab. Các Spark Steps được nộp trực tiếp từ S3 và tự động thực thi. Nhờ cờ `--auto-terminate`, cụm EMR tự động Terminate ngay sau khi hoàn thành toàn bộ bài chạy, giải phóng hoàn toàn tài nguyên để tối ưu chi phí."

---

### PHẦN 4: CLOUDWATCH DASHBOARD & KẾT QUẢ BENCHMARK (5:45 - 7:15)
* **Thao tác màn hình:**
  1. Mở **AWS CloudWatch Console** -> **Dashboards**: Show màn hình dashboard giám sát tài nguyên thời gian thực với các biểu đồ `CPUUtilization`, `mem_used_percent` và `disk_used_percent` nhô đỉnh trong quá trình chạy bài test.
  2. Mở **CloudWatch Alarms**: Show 1 Alarm được cấu hình cảnh báo khi CPU chạm ngưỡng 85%.
  3. Mở file ảnh biểu đồ so sánh `docs/evidence/w4/emr-self-managed-runtime.png` và bảng tổng hợp `benchmark/summary-w4.md`:
     - Show số liệu WordCount 1GB: Self-Managed tốn 210.0s (sau khi tối ưu `spark.sql.shuffle.partitions`) vs EMR tốn 142.5s.
     - Show số liệu WordCount 5GB: Self-Managed tốn 982.0s vs EMR tốn 635.0s.

* **Lời thuyết minh:**
  > "Hệ thống được giám sát qua AWS CloudWatch Agent với tần số thu thập 60 giây và tích hợp Alarm cảnh báo khi CPU vượt 85%. Kết quả benchmark qua 24 lượt chạy đối soát cho thấy cụm EMR cho hiệu năng thực thi nhanh hơn khoảng 35-40% so với EC2 Self-Managed ở các tập dữ liệu lớn từ 3GB đến 5GB, nhờ lợi thế bộ nhớ RAM 8GB/node và khả năng tối ưu sẵn của EMR Runtime."

---

### PHẦN 5: DỌN DẸP TÀI NGUYÊN & BÁO CÁO CHI PHÍ (7:15 - 8:00)
* **Thao tác màn hình:**
  1. Mở CloudShell: Chạy script `infra/cleanup-nhu.sh` và `infra/cleanup.sh`. Show dòng lệnh xóa stack CloudFormation `aws cloudformation delete-stack` và kiểm tra dừng toàn bộ instance EC2.
  2. Mở **EC2 Console**: Show toàn bộ các máy EC2 đã ở trạng thái `Terminated` / `Stopped`.
  3. Mở trang **AWS Learner Lab Credit Report** (`docs/evidence/w4/aws-cost-report.png`): Show tổng chi phí đã sử dụng nằm trong giới hạn ngân sách được cấp.

* **Lời thuyết minh:**
  > "Sau khi thu thập đủ dữ liệu benchmark, toàn bộ tài nguyên được dọn dẹp bằng script CLI. Stack CloudFormation bị xóa, các EC2 instance bị Terminate và EMR cluster đã được giải phóng. Thư mục kết quả trên S3 được bảo lưu phục vụ nộp bài. Báo cáo chi phí ghi nhận tổng ngân sách tiêu thụ nằm trong hạn mức an toàn của phiên AWS Learner Lab."
