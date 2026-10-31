# KỊCH BẢN QUAY MÀN HÌNH DEMO DỰ ÁN (KHÔNG GHI ÂM)
**Đề tài:** Triển khai cụm Hadoop/Spark tự dựng trên EC2 và so sánh với Amazon EMR  
**Thực hiện:** Lê Huỳnh Như (24139035) & Đỗ Minh Hiển (24139013)  
**Repository:** https://github.com/lhuynhu06-beep/DTDM  

---

## ⏱️ TỔNG QUAN THỜI LƯỢNG CLIP (~5 - 6 PHÚT)

| Phần | Thời lượng | Thao tác chính trên AWS Console / CLI | Chữ chú thích chèn lên clip (Caption) |
| :--- | :--- | :--- | :--- |
| **Phần 1** | 0:00 - 1:00 | S3 Bucket, Block Public Access, Policy Cross-Account, SSE-S3 | **Phần 1: Hạ tầng lưu trữ Amazon S3 & Bảo mật Cross-Account** |
| **Phần 2** | 1:00 - 2:30 | Stack CloudFormation `CREATE_COMPLETE`, EC2 Instances, YARN UI, `spark-submit` | **Phần 2: Nhánh Self-Managed — CloudFormation IaC & EC2 Cluster** |
| **Phần 3** | 2:30 - 4:00 | CloudShell chạy `emr-create.sh`, EMR Steps Console, S3 Results | **Phần 3: Nhánh Managed Service — Tự động hóa Amazon EMR qua CLI** |
| **Phần 4** | 4:00 - 5:00 | CloudWatch Dashboard, Alarms, Biểu đồ Benchmark runtime | **Phần 4: Giám sát CloudWatch Metrics & Kết quả Benchmark** |
| **Phần 5** | 5:00 - 5:30 | CLI `cleanup.sh`, EC2 Terminated, AWS Cost Report | **Phần 5: Dọn dẹp tài nguyên (Cleanup) & Báo cáo chi phí** |

---

## 🎬 NỘI DUNG THAO TÁC MÀN HÌNH CHI TIẾT

### PHẦN 1: AMAZON S3 & PHÂN QUYỀN CROSS-ACCOUNT (0:00 - 1:00)
* **Thao tác 1:** Mở trang chủ AWS Console, di chuột chỉ vào **Account ID** (`9337-3325-7957`) và Region `us-east-1`.
* **Thao tác 2:** Mở S3 Bucket `s3://hadoop-spark-lab-24139035`.
* **Thao tác 3:** Mở tab **Permissions**: Show dòng *Block All Public Access (On)* và dán file Policy `infra/s3-bucket-policy.json` cấp quyền cho Role `LabRole` của Hiển.
* **Thao tác 4:** Mở tab **Properties**: Show mã hóa *SSE-S3* và Tags (`Project=HadoopSpark-EC2-vs-EMR`, `Owner=24139035`).
* **Thao tác 5:** Mở các thư mục `/data/` (chứa các file 1GB, 3GB, 5GB), `/jobs/` (`wordcount.py`, `aggregation.py`), `/logs/`, và `/results/`.

📌 *Caption chèn trên clip:*  
> **[S3 Storage Setup]** Bucket `s3://hadoop-spark-lab-24139035` (Region us-east-1)  
> **[Security]** Block Public Access + Encrypted SSE-S3 + Cross-Account Policy cho LabRole.

---

### PHẦN 2: CỤM EC2 SELF-MANAGED BẰNG CLOUDFORMATION (1:00 - 2:30)
* **Thao tác 1:** Mở AWS CloudFormation -> Show Stack `hadoop-cfn` ở trạng thái `CREATE_COMPLETE` (thời gian khởi tạo: 4m37s).
* **Thao tác 2:** Mở EC2 Console -> Show 3 máy `t3.medium` (`master`, `worker1`, `worker2`) gắn `LabInstanceProfile` và Tag `Owner=24139013`.
* **Thao tác 3:** Mở browser qua SSH Tunnel -> Truy cập **NameNode Web UI (port 9870)** show 2 Live DataNodes và **YARN UI (port 8088)**.
* **Thao tác 4:** Mở Terminal -> Chạy lệnh `spark-submit` nộp job PySpark WordCount đọc trực tiếp đường dẫn `s3a://`.
* **Thao tác 5:** Mở S3 Console -> Show thư mục kết quả `/results/self-managed/`.

📌 *Caption chèn trên clip:*  
> **[Self-Managed IaC]** CloudFormation dựng 3 node EC2 t3.medium trong 4 phút 37 giây.  
> **[Spark-on-YARN]** Chạy job PySpark đọc S3 qua S3A Connector & LabInstanceProfile.

---

### PHẦN 3: TỰ ĐỘNG HÓA CỤM AMAZON EMR BẰNG AWS CLI (2:30 - 4:00)
* **Thao tác 1:** Mở AWS CloudShell -> Chạy script `infra/emr-create.sh` với lệnh `aws emr create-cluster` kèm cờ `--auto-terminate`.
* **Thao tác 2:** Mở EMR Console -> Show cụm chuyển trạng thái `STARTING` -> `RUNNING`.
* **Thao tác 3:** Mở tab **Steps** -> Show các Step (`WordCount`, `Aggregation`) chuyển sang `COMPLETED` (xử lý Step *ChiPheo.txt* trong 50 giây).
* **Thao tác 4:** Mở S3 Console -> Show kết quả ghi vào `/results/emr/` với file `_SUCCESS` và `part-00000`. Cụm EMR tự động chuyển trạng thái sang `TERMINATED`.

📌 *Caption chèn trên clip:*  
> **[Managed EMR]** Tự động khởi tạo cụm EMR emr-6.10.x (3 node m4.large) qua AWS CLI.  
> **[Auto-Terminate]** Submit Step PySpark từ S3 và tự động giải phóng cụm ngay khi hoàn thành.

---

### PHẦN 4: CLOUDWATCH MONITORING & KẾT QUẢ BENCHMARK (4:00 - 5:00)
* **Thao tác 1:** Mở AWS CloudWatch -> Show **Dashboard** hiển thị biểu đồ CPUUtilization, RAM, Disk spike khi đang chạy job.
* **Thao tác 2:** Show **CloudWatch Alarm** cảnh báo khi CPU > 85%.
* **Thao tác 3:** Mở file ảnh biểu đồ `docs/evidence/w4/emr-self-managed-runtime.png` và file tổng hợp `benchmark/summary-w4.md`.

📌 *Caption chèn trên clip:*  
> **[Monitoring]** CloudWatch Agent giám sát CPU, RAM, Disk thời gian thực & Cảnh báo Alarm CPU > 85%.  
> **[Benchmark]** Amazon EMR cho hiệu năng thực thi nhanh hơn ~35-40% so với EC2 Self-Managed.

---

### PHẦN 5: DỌN DẸP TÀI NGUYÊN & BÁO CÁO CHI PHÍ (5:00 - 5:30)
* **Thao tác 1:** Mở CloudShell -> Chạy script `infra/cleanup.sh` và `infra/cleanup-nhu.sh`.
* **Thao tác 2:** Mở EC2 Console -> Show toàn bộ máy EC2 ở trạng thái `Terminated` / `Stopped`.
* **Thao tác 3:** Mở trang **AWS Learner Lab Credit Report** (`docs/evidence/w4/aws-cost-report.png`) chứng minh tổng chi phí trong hạn mức.

📌 *Caption chèn trên clip:*  
> **[Cleanup & Cost]** Dọn dẹp tài nguyên qua AWS CLI script. Ngân sách Learner Lab được bảo đảm an toàn.
