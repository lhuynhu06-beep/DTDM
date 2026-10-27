# Báo Cáo Tổng Hợp & Phân Tích Kết Quả Benchmark Tuần 4 - Nhóm DTD-M

**Đề tài:** Triển khai cụm Hadoop/Spark tự dựng trên EC2 và so sánh với Amazon EMR  
**Môn học:** Cloud – Đợt 1 – 2026-2027  
**GVHD:** Huỳnh Xuân Phụng (phunghx@hcmute.edu.vn)  
**Thời lượng:** 4 tuần | **Trạng thái:** Hoàn thành  
**Thành viên thực hiện:**
* **Lê Huỳnh Như** – 24139035 (Trưởng nhóm - Nhánh EMR & Dữ liệu)
* **Đỗ Minh Hiển** – 24139013 (Thành viên - Nhánh Self-managed EC2)


## 1. Yêu Cầu Chung Của Dự Án & Tuyên Bố Hỗ Trợ AI

* **Quy mô & Nhật ký:** Nhóm tối đa 2 SV; hoàn thành trong 4 tuần; nộp nhật ký công việc (worklog) hằng tuần ghi rõ phân công và số giờ của từng SV.
* **Hạn chế AWS Hạ tầng:** Dùng Region us-east-1, LabRole / LabInstanceProfile, EC2 loại nano → large (tối đa ≤ 9 instance, ≤ 32 vCPU), EBS ≤ 100 GB (gp2/gp3). Gắn tag đầy đủ, stop/terminate tài nguyên sau mỗi buổi.
* **Ghi rõ phần nào có AI hỗ trợ (Theo yêu cầu môn học):**
  * **Công cụ & Model:** Sử dụng Gemini (Google) để hỗ trợ trong suốt quá trình thực hiện dự án.
  * **Prompt tham khảo chính:** "Hỗ trợ viết script cấu hình tự động, tối ưu tham số Spark, sinh template CloudFormation và hỗ trợ định dạng báo cáo Markdown."
  * **Nội dung AI hỗ trợ:** Gợi ý cấu trúc file script tự động hóa cài đặt Hadoop/Spark, hỗ trợ sinh cú pháp câu lệnh AWS CLI và cấu trúc file CloudFormation YAML.
  * **Phần thành viên đã tự sửa & kiểm chứng:** Toàn bộ mã nguồn, kịch bản template đã được nhóm kiểm tra, chạy thử nghiệm thực tế (run-test) trên AWS Learner Lab, chỉnh sửa lại các thông số IP/DNS, tuỳ chỉnh bộ nhớ phù hợp với instance t3.medium và m4.xlarge, đồng thời tự viết phần phân tích kết quả benchmark, biểu đồ và nhận xét thực tế.


## 2. Bảng Phân Công Nhiệm Vụ Chi Tiết 4 Tuần

### Tuần 1: Tìm hiểu, thiết kế kiến trúc, dựng nền tảng (5/10 – 10/10/2026)
* **Cả hai (1h):** Họp khởi động, chốt Region, quy ước tag, cấu trúc Git.  
  * *Minh chứng:* [docs/meeting-w1.md](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/meeting-w1.md)
* **Đỗ Minh Hiển (9h):** Thiết kế cụm 1 master + 2 worker t3.medium, cài đặt Hadoop 3 & Spark 3.  
  * *Minh chứng:* [Sơ đồ kiến trúc](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/diagrams/self-managed-architecture.png) | [setup-base.sh](https://github.com/lhuynhu06-beep/DTDM/blob/main/scripts/setup-base.sh) | [Worklog W1 Hiển](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/worklog/w1-hien.md)
* **Lê Huỳnh Như (8h):** Tạo repo Git, thiết lập S3 bucket (data/, jobs/, logs/, results/), chuẩn bị dataset và viết PySpark job.  
  * *Minh chứng:* [Repo DTDM](https://github.com/lhuynhu06-beep/DTDM) | [wordcount.py](https://github.com/lhuynhu06-beep/DTDM/blob/main/jobs/wordcount.py) | [Ảnh Tag Bucket S3](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w1/TagBucketS3.png)

### Tuần 2: Triển khai chức năng lõi, kiểm thử từng thành phần (12/10 – 17/10/2026)
* **Đỗ Minh Hiển (10.5h):** Cấu hình HDFS/YARN, cài Spark on YARN kết nối S3A.  
  * *Minh chứng:* [HDFS & YARN Report](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w2/01-hdfs-report-yarn-nodes-jps.jpg) | [spark-defaults.conf](https://github.com/lhuynhu06-beep/DTDM/blob/main/conf/spark/spark-defaults.conf)
* **Lê Huỳnh Như (7.5h):** Tạo cụm EMR (m4.xlarge), submit step job từ S3, viết script infra/emr-create.sh.  
  * *Minh chứng:* [EMR Cluster Console](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w2/emr-cluster.png) | [emr-create.sh](https://github.com/lhuynhu06-beep/DTDM/blob/main/infra/emr-create.sh)

### Tuần 3: Tích hợp, bảo mật, giám sát, IaC, chạy benchmark (19/10 – 24/10/2026)
* **Đỗ Minh Hiển (9.5h):** Viết CloudFormation template infra/self-managed.yaml, tích hợp CloudWatch Agent, chạy benchmark cụm tự dựng.  
  * *Minh chứng:* [self-managed.yaml](https://github.com/lhuynhu06-beep/DTDM/blob/main/infra/self-managed.yaml) | [CloudWatch Dashboard](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w3/03-cloudwatch-dashboard.jpg) | [results-self-managed.csv](https://github.com/lhuynhu06-beep/DTDM/blob/main/benchmark/results-self-managed.csv)
* **Lê Huỳnh Như (7.5h):** Bảo mật EMR & S3, bật CloudWatch Metrics, chạy benchmark EMR, lập bảng chi phí cost.csv.  
  * *Minh chứng:* [S3 Block Public Access](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w3/s3-block-public-access.png) | [results.csv](https://github.com/lhuynhu06-beep/DTDM/blob/main/benchmark/results.csv)

### Tuần 4: Kiểm thử tổng thể, tối ưu chi phí, dọn dẹp, báo cáo và demo (26/10 – 31/10/2026)
* **Đỗ Minh Hiển (8.5h):** Tối ưu Spark (giúp WordCount 1GB giảm 9.3% thời gian), viết chương báo cáo, quay clip demo, dọn dẹp tài nguyên.  
  * *Minh chứng:* [summary-self-managed.md](https://github.com/lhuynhu06-beep/DTDM/blob/main/benchmark/summary-self-managed.md) | [chuong-self-managed-hien.md](https://github.com/lhuynhu06-beep/DTDM/blob/main/report/chuong-self-managed-hien.md)
* **Lê Huỳnh Như (8.5h):** Phân tích kết quả, vẽ biểu đồ runtime, viết nhận xét EMR vs Self-managed, tổng hợp báo cáo và dọn dẹp tài nguyên EMR/S3.  
  * *Minh chứng:* [Biểu đồ Runtime](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/emr-vs-self-managed-runtime.png) | [Báo cáo chi phí AWS](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/aws-cost-report.png)


## 3. Kết Quả Benchmark & Biểu Đồ Runtime

* **Link Biểu đồ Runtime trực quan:** [emr-vs-self-managed-runtime.png](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/emr-vs-self-managed-runtime.png)
* **Link File Dữ liệu Thô:** [results.csv (EMR)](https://github.com/lhuynhu06-beep/DTDM/blob/main/benchmark/results.csv) | [results-self-managed.csv](https://github.com/lhuynhu06-beep/DTDM/blob/main/benchmark/results-self-managed.csv)

### Bảng So Sánh Hiệu Năng WordCount Job:
| Cụm Máy Chủ | Cấu Hình Instance | Kích Thước Dữ Liệu | Thời Gian Chạy (Runtime) | Trạng Thái |
| :--- | :--- | :---: | :---: | :---: |
| **Amazon EMR (Như)** | m4.xlarge (3 nodes) | Standard Benchmark | **40.0s** | Completed |
| **Self-managed Tuned (Hiển)** | t3.medium (3 nodes) | 1 GB | **210.0s** | Completed |
| **Self-managed Baseline (Hiển)** | t3.medium (3 nodes) | 1 GB | **227.4s** | Completed |
| **Self-managed Baseline (Hiển)** | t3.medium (3 nodes) | 3 GB | **577.4s** | Completed |
| **Self-managed Baseline (Hiển)** | t3.medium (3 nodes) | 5 GB | **943.2s** | Completed |

* **Phân tích:** Cụm Amazon EMR hoàn thành chỉ trong 40 giây nhờ phần cứng mạnh mẽ (m4.xlarge) và cơ chế quản lý tự động của AWS. Trong khi đó, cụm Self-managed (t3.medium CPU burstable) mất từ 210s đến 943s tùy thuộc vào kích thước dữ liệu.


## 4. Bảng Công Sức & Chi Phí
* **Số bước công việc (Steps):** Hoàn thành 100% các mốc theo kế hoạch 4 tuần.
* **Giờ công:** Lê Huỳnh Như (31.5h) | Đỗ Minh Hiển (38.5h).
* **Chi phí AWS:** Nằm trong hạn mức credit của tài khoản AWS Academy Learner Lab, không phát sinh chi phí ngoài ý muốn nhờ tuân thủ quy tắc tắt tài nguyên.


## 5. Nhận Xét: Khi Nào Tự Dựng vs. Khi Nào Dùng EMR?
* **Chọn Cụm Tự Dựng (Self-managed):** Phù hợp cho việc nghiên cứu sâu kiến trúc Hadoop/YARN/Spark, môi trường R&D học tập với chi phí cố định. Nhược điểm tốn nhiều giờ công cấu hình và không co giãn tự động.
* **Chọn Amazon EMR:** Phù hợp cho môi trường Production xử lý Big Data với tốc độ vượt trội, tính ổn định cao, tự động co giãn và tiết kiệm thời gian vận hành DevOps.


## 6. Minh Chứng Dọn Dẹp Tài Nguyên AWS & Chi Phí
* **Ảnh EMR Terminated:** [emr-terminated.png](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/emr-terminated.png)
* **Ảnh EC2 Stopped:** [ec2-stopped.png](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/ec2-stopped.png)
* **Ảnh AWS Cost Report:** [aws-cost-report.png](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/aws-cost-report.png)
