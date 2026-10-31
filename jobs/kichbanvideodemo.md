# KỊCH BẢN QUAY MÀN HÌNH DEMO DỰ ÁN (PHÂN CÔNG THEO THÀNH VIÊN)

**Đề tài:** Triển khai cụm Hadoop/Spark tự dựng trên EC2 và so sánh với Amazon EMR  
**Thực hiện:** Lê Huỳnh Như (24139035 - Trưởng nhóm) & Đỗ Minh Hiển (24139013)  
**Repository:** https://github.com/lhuynhu06-beep/DTDM  

---

## ⏱️ PHÂN CÔNG VÀ TỔNG QUAN THỜI LƯỢNG (8 PHÚT)

| Mốc thời gian | Nội dung | Phụ trách | Thao tác thực tế trên màn hình | Dòng chữ Caption chèn trên Video |
| :--- | :--- | :--- | :--- | :--- |
| **0:00 - 1:30** | **Phần 1** | **Lê Huỳnh Như** | S3 Bucket, Block Public Access, Policy Cross-Account, file data `ChiPheo.txt` | **Phần 1: Hạ tầng Amazon S3 & Bảo mật Cross-Account (Thực hiện: Lê Huỳnh Như)** |
| **1:30 - 3:45** | **Phần 2** | **Đỗ Minh Hiển** | Stack CloudFormation `CREATE_COMPLETE`, EC2 Instances (3 node t3.medium), YARN UI, nộp job `spark-submit` | **Phần 2: Cụm EC2 Self-Managed bằng CloudFormation IaC (Thực hiện: Đỗ Minh Hiển)** |
| **3:45 - 6:00** | **Phần 3** | **Lê Huỳnh Như** | CloudShell chạy script `emr-create.sh`, EMR Steps Console xử lý `ChiPheo.txt`, cụm Auto-Terminate | **Phần 3: Tự động hóa cụm Amazon EMR qua AWS CLI (Thực hiện: Lê Huỳnh Như)** |
| **6:00 - 7:15** | **Phần 4** | **Đỗ Minh Hiển** | CloudWatch Dashboard (CPU/RAM/Disk), CloudWatch Alarm, Biểu đồ & Bảng số liệu Benchmark đối soát | **Phần 4: Giám sát CloudWatch & Kết quả Benchmark (Thực hiện: Đỗ Minh Hiển)** |
| **7:15 - 8:00** | **Phần 5** | **Lê Huỳnh Như** | CloudShell chạy `cleanup-nhu.sh`, trạng thái EC2 Terminated/Stopped, Báo cáo chi phí AWS Learner Lab | **Phần 5: Dọn dẹp tự động (Cleanup) & Báo cáo chi phí (Thực hiện: Lê Huỳnh Như)** |

---

## 🎬 NỘI DUNG CHI TIẾT THEO THÀNH VIÊN

### 📌 PHẦN 1: AMAZON S3 & PHÂN QUYỀN CROSS-ACCOUNT (0:00 - 1:30)
**Người phụ trách:** Lê Huỳnh Như (24139035)

* **Thao tác màn hình (Như):**
  1. Mở trang chủ AWS Console, chỉ rõ **Account ID** (`9337-3325-7957`) và Region `us-east-1`.
  2. Mở dịch vụ **Amazon S3** -> Chọn Bucket `s3://hadoop-spark-lab-24139035`.
  3. Mở tab **Permissions**: Show cấu hình `Block all public access = On` và cuộn xuống đoạn **S3 Bucket Policy** (`infra/s3-bucket-policy.json`) cấp quyền Cross-Account cho `LabRole` của Hiển.
  4. Mở tab **Properties**: Show dòng mã hóa `SSE-S3` và bảng **Tags** (`Project=HadoopSpark-EC2-vs-EMR`, `Owner=24139035`).
  5. Mở danh sách thư mục: Show thư mục `data/` (chứa duy nhất file dữ liệu truyện văn học `ChiPheo.txt`), thư mục `jobs/` (`wordcount.py`, `aggregation.py`), `logs/` và `results/`.

📌 *Caption chèn video:*  
> **Phần 1 [Lê Huỳnh Như]:** Khởi tạo S3 Bucket `s3://hadoop-spark-lab-24139035` (Mã hóa SSE-S3 & Block Public Access)  
> Phân quyền Cross-Account cho LabRole và lưu trữ file dữ liệu đầu vào ChiPheo.txt tại phân vùng data/.

---

### 📌 PHẦN 2: CỤM EC2 SELF-MANAGED BẰNG CLOUDFORMATION (1:30 - 3:45)
**Người phụ trách:** Đỗ Minh Hiển (24139013)

* **Thao tác màn hình (Hiển):**
  1. Mở **AWS CloudFormation** -> Click vào Stack `hadoop-cfn` ở trạng thái `CREATE_COMPLETE` (chỉ vào thời gian khởi tạo tự động là 4m37s).
  2. Mở **EC2 Console** -> Show 3 máy `t3.medium` (`master`, `worker1`, `worker2`), cho thấy các máy gắn đúng `LabInstanceProfile` và Tag `Owner=24139013`.
  3. Chuyển sang trình duyệt qua SSH Tunnel -> Mở **NameNode UI (cổng 9870)** show 2 Live DataNodes và **YARN UI (cổng 8088)**.
  4. Mở Terminal/Putty -> Chạy lệnh `spark-submit` nộp job PySpark WordCount đọc trực tiếp file `s3a://hadoop-spark-lab-24139035/data/ChiPheo.txt`.
  5. Quay lại S3 Console -> Mở folder `/results/self-managed/` show kết quả được ghi thành công.

📌 *Caption chèn video:*  
> **Phần 2 [Đỗ Minh Hiển]:** Cụm EC2 Self-Managed (3 node t3.medium) dựng bằng CloudFormation IaC trong 4 phút 37 giây.  
> Vận hành Hadoop 3.3/Spark 3.5 trên YARN, xử lý file ChiPheo.txt trực tiếp từ S3 qua S3A Connector.

---

### 📌 PHẦN 3: TỰ ĐỘNG HÓA CỤM AMAZON EMR BẰNG AWS CLI (3:45 - 6:00)
**Người phụ trách:** Lê Huỳnh Như (24139035)

* **Thao tác màn hình (Như):**
  1. Mở **AWS CloudShell** -> Chạy script `infra/emr-create.sh` để thực thi lệnh `aws emr create-cluster` (chỉ chuột vào tham số `--auto-terminate`).
  2. Mở web **Amazon EMR Console** -> Click vào cụm EMR chuyển từ `STARTING` sang `RUNNING`.
  3. Mở tab **Steps** -> Show Spark Step `WordCount` xử lý file `ChiPheo.txt` nộp từ S3 chuyển trạng thái sang `COMPLETED` thành công trong 50 giây.
  4. Mở S3 Console -> Show thư mục `/results/emr/` có file đánh dấu `_SUCCESS` và file dữ liệu `part-00000`. Show thư mục `/logs/` chứa các folder Cluster ID (`j-...`) lưu log tự động.
  5. Quay lại EMR Console -> Show cụm EMR tự động chuyển sang trạng thái `TERMINATED` để tiết kiệm chi phí.

📌 *Caption chèn video:*  
> **Phần 3 [Lê Huỳnh Như]:** Tự động hóa tạo cụm EMR (emr-5.36.x, 3 node m4.large) bằng AWS CLI.  
> Thực thi Spark Step đếm từ file ChiPheo.txt hoàn tất trong 50 giây và bật Auto-Terminate giải phóng cụm.

---

### 📌 PHẦN 4: CLOUDWATCH MONITORING & KẾT QUẢ BENCHMARK (6:00 - 7:15)
**Người phụ trách:** Đỗ Minh Hiển (24139013)

* **Thao tác màn hình (Hiển):**
  1. Mở **AWS CloudWatch Console** -> Mở mục **Dashboards** show các biểu đồ `CPUUtilization`, `mem_used_percent` và `disk_used_percent` nhô đỉnh khi chạy job.
  2. Mở mục **Alarms** -> Show 1 Alarm được thiết lập cảnh báo tự động khi CPU chạm ngưỡng 85%.
  3. Mở file ảnh biểu đồ `emr-self-managed-runtime.png` và file tổng hợp `benchmark/summary-w4.md` đối soát dữ liệu thực nghiệm benchmark giữa 2 cụm.

📌 *Caption chèn video:*  
> **Phần 4 [Đỗ Minh Hiển]:** Giám sát CloudWatch Metrics (CPU, RAM, Disk) & Cảnh báo Alarm CPU > 85%.  
> Đối soát Benchmark: Amazon EMR tối ưu thời gian thực thi tốt hơn nhờ hạ tầng Managed Service và cấu hình node m4.large.

---

### 📌 PHẦN 5: DỌN DẸP TÀI NGUYÊN (CLEANUP) & CHI PHÍ (7:15 - 8:00)
**Người phụ trách:** Lê Huỳnh Như (24139035)

* **Thao tác màn hình (Như):**
  1. Mở **CloudShell** -> Chạy script `infra/cleanup-nhu.sh` và `infra/cleanup.sh` (xóa stack CloudFormation và cụm EMR).
  2. Quay lại **EC2 Console** -> Show danh sách máy EC2 đã chuyển sang trạng thái `Terminated` / `Stopped`.
  3. Mở trang **AWS Learner Lab Credit Report** (`docs/evidence/w4/aws-cost-report.png`) show tổng chi phí sử dụng an toàn trong hạn mức được cấp.

📌 *Caption chèn video:*  
> **Phần 5 [Lê Huỳnh Như]:** Chạy script CLI dọn dẹp toàn bộ tài nguyên (Xóa Stack CloudFormation, Terminate EC2).  
> Báo cáo chi phí AWS Learner Lab được bảo đảm an toàn trong ngân sách.
