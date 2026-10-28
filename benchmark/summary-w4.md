# Tổng Hợp Kết Quả Báo Cáo Tuần 4 – Benchmark & So Sánh EMR vs Self-Managed (EC2)

**Dự án:** Triển khai cụm Hadoop/Spark tự dựng trên EC2 và so sánh với Amazon EMR  
**Môn học:** Cloud – Đợt 1 (2026–2027)  
**Giảng viên hướng dẫn:** Huỳnh Xuân Phụng  
**Thực hiện:**  
- Lê Huỳnh Như – 24139035 (Trưởng nhóm)  
- Đỗ Minh Hiển – 24139013  

---

## 1. So Sánh Thời Gian Thực Thi (Runtime Benchmark)

Thử nghiệm được tiến hành trên 3 mức dữ liệu (1GB, 3GB, 5GB) cho 2 tác vụ Spark: **WordCount** và **Aggregation**. Mỗi thử nghiệm chạy 3 lần để lấy giá trị trung bình (tính bằng giây).

### 1.1. Bảng số liệu chi tiết (Runtime in Seconds)

| Kích thước dữ liệu | Tác vụ (Job) | Self-Managed (Trước tối ưu) | Self-Managed (Sau tối ưu) | Amazon EMR | Chênh lệch (EMR vs SM Sau tối ưu) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **1 GB** | **WordCount** | 231.4 s | **210.0 s** | **142.5 s** | EMR nhanh hơn ~32.1% |
| **1 GB** | **Aggregation** | 185.0 s | **168.2 s** | **112.0 s** | EMR nhanh hơn ~33.4% |
| **3 GB** | **WordCount** | 645.2 s | **588.0 s** | **385.0 s** | EMR nhanh hơn ~34.5% |
| **3 GB** | **Aggregation** | 512.0 s | **465.5 s** | **302.0 s** | EMR nhanh hơn ~35.1% |
| **5 GB** | **WordCount** | 1,080.5 s | **982.0 s** | **635.0 s** | EMR nhanh hơn ~35.3% |
| **5 GB** | **Aggregation** | 860.0 s | **780.0 s** | **501.0 s** | EMR nhanh hơn ~35.8% |

> **Biểu đồ minh chứng:** `docs/evidence/w4/emr-vs-self-managed-runtime.png`

### 1.2. Nhận xét về Hiệu năng
1. **Amazon EMR vượt trội từ 32% - 36%:** EMR xử lý nhanh hơn ở tất cả các mức dữ liệu nhờ vào bộ tối ưu hóa **EMR Runtime for Apache Spark** tích hợp sẵn cùng dung lượng RAM lớn hơn (`m4.large` - 8 GiB RAM/node vs `t3.medium` - 4 GiB RAM/node).
2. **Khả năng mở rộng tuyến tính:** Thời gian xử lý của cả 2 cụm đều tăng tuyến tính theo kích thước dữ liệu (từ 1GB đến 5GB).
3. **Hiệu quả tối ưu hóa trên cụm Tự dựng:** Sau khi tinh chỉnh các tham số Spark (`spark.executor.memory`, `spark.driver.memory`, `spark.sql.shuffle.partitions`), cụm Self-Managed cải thiện được **~9.3%** thời gian xử lý so với cấu hình mặc định.

---

## 2. Giám Sát Cụm Trực Tuyến (CloudWatch Metrics Analysis)

Dựa trên dữ liệu thu thập trực tiếp từ AWS CloudWatch cho cụm EMR (`JobFlowId: j-0054312342KWHFQCHNSM` tại thời điểm 2026-10-28 14:30:00 UTC):

- **IsIdle = 1:** Cho biết cụm EMR đang ở trạng thái nhàn rỗi sau khi hoàn thành các bước tính toán (Steps).
- **AppsRunning = 0:** Không có ứng dụng Spark nào đang thực thi, đảm bảo toàn bộ tài nguyên đã được giải phóng.
- **HDFSUtilization = 0:** Dữ liệu đầu vào và kết quả đầu ra đều được đọc/ghi trực tiếp từ Amazon S3, không lưu trữ lâu dài trên HDFS của cụm, giúp tối ưu bộ nhớ lưu trữ.

---

## 3. Báo Cáo Chi Phí Sử Dụng AWS (AWS Billing & Cost Management)

Dựa trên dữ liệu thực tế trích xuất từ bảng điều khiển **Billing and Cost Management** (Tài khoản ID: `9337-3325-7957` / `24139035@student.hcmute.edu.vn`):

- **Tổng chi phí thực tế tính đến hiện tại (Cost MTD):** **US$ 1.74**
- **Dự báo tổng chi phí cả tháng (Projected Cost):** **US$ 1.75** (nằm trong giới hạn ngân sách $100 của AWS Learner Lab).
- **Phân rã chi phí theo Dịch vụ (Service Breakdown):**
  - **Amazon Elastic Compute Cloud (EC2 - Compute):** Chiếm tỷ trọng lớn nhất (~ **$1.20**) do duy trì các instance `t3.medium` cho cụm Self-Managed trong quá trình cấu hình và benchmark.
  - **Amazon Elastic MapReduce (EMR):** Chiếm khoảng **$0.25**, tối ưu nhờ cơ chế khởi chạy dạng Transient Cluster (chạy xong step tự terminate).
  - **Amazon Virtual Private Cloud (VPC) & EC2 - Other:** Chiếm khoảng **$0.20** (Network & EBS Volume).
  - **Amazon Simple Storage Service (S3):** Chi phí rất thấp (~ **$0.09**) nhờ lưu trữ dữ liệu dạng text/csv gọn nhẹ.

---

## 4. Kết Luận & Đề Xuất Trường Hợp Sử Dụng (Use Cases)

### 4.1. Khi nào nên dùng Self-Managed (EC2)?
- **Ngân sách hạ tầng cố định:** Tối ưu chi phí chạy liên tục 24/7 ở quy mô nhỏ.
- **Yêu cầu tùy biến sâu:** Cần can thiệp chi tiết vào cấu hình hệ thống Hadoop HDFS, YARN hoặc các thư viện riêng.
- **Mục đích học tập/nghiên cứu:** Cần nắm rõ cơ chế vận hành bên trong của cụm Big Data.

### 4.2. Khi nào nên dùng Amazon EMR?
- **Môi trường Doanh nghiệp (Production):** Cần triển khai nhanh, tự động hóa cao, không mất công bảo trì hạ tầng.
- **Xử lý dữ liệu định kỳ (Batch Processing):** Tận dụng tính năng Transient Cluster (chạy xong tự xóa cụm) để tiết kiệm chi phí chờ nhàn rỗi.
- **Big Data quy mô lớn:** Cần tối ưu thời gian xử lý nhanh hơn 30% - 35% nhờ EMR Runtime.
