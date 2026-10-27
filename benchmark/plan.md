# Benchmark Plan & Protocol

## 1. Mục tiêu
Thống nhất quy chuẩn thực thi benchmark trên cụm Amazon EMR để so sánh hiệu năng xử lý dữ liệu giữa các cấu hình phần cứng và phương thức triển khai khác nhau.

## 2. Giao thức thử nghiệm (Benchmark Protocol)
* **Workload:** Chạy cùng một Job xử lý dữ liệu chuẩn (WordCount / Data Aggregation từ S3).
* **Dataset:** Cùng một tập dữ liệu đầu vào trên S3 bucket (`s3://hadoop-spark-lab-24139035/`).
* **Số lần lặp lại:** Mỗi mức dữ liệu chạy lặp lại **3 lần** và lấy kết quả trung bình để đảm bảo tính khách quan.
* **Topology:** Cố định cấu hình mô hình **1 Master + 2 Worker** ở tất cả các cụm thử nghiệm.
* **Chỉ số đo lường (Metrics):**
  * Thời gian khởi tạo cụm (Cluster Provisioning Time)
  * Thời gian chạy Job (Job Execution Time)
  * Chi phí tài nguyên (AWS Cost)
