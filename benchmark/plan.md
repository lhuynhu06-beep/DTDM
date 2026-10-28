# Benchmark Plan & Protocol

## 1. Mục tiêu
Thống nhất quy chuẩn thực thi bài thử nghiệm (benchmark) giữa cụm tự dựng (Self-managed trên EC2) và cụm Managed Service (Amazon EMR) để đưa ra so sánh khách quan về hiệu năng, chi phí và công sức triển khai.

## 2. Giao thức thử nghiệm (Benchmark Protocol)
*   **Workload:** Chạy đồng thời 2 loại tác vụ xử lý dữ liệu lớn: WordCount (Đếm tần suất từ) và Data Aggregation (Gom nhóm thống kê dữ liệu).
*   **Dataset:** Sử dụng các tệp dữ liệu chuẩn lưu trữ tập trung trên Amazon S3 bucket (`s3://hadoop-spark-lab-24139035/data/`) với 3 mức dung lượng: 1 GiB (Baseline), 3 GiB và 5 GiB (Stress test).
*   **Số lần lặp lại:** Mỗi mức dữ liệu và mỗi loại job trên từng cụm phải được chạy lặp lại 3 lần để lấy kết quả trung bình, loại bỏ sai số do trễ mạng hoặc khởi động nguội.
*   **Topology Hệ thống:** Cố định cấu hình mô hình cấu trúc cụm bao gồm 1 Master Node + 2 Worker Nodes cho cả hai môi trường thực nghiệm.

## 3. Khác biệt cấu hình phần cứng hệ thống

| Thành phần cụm | Cụm tự dựng (Self-managed EC2 của Hiển) | Cụm Dịch vụ (Amazon EMR của Như) |
| :--- | :--- | :--- |
| **Loại Instance** | `t3.medium` | `m4.large` |
| **Thông số Core** | 2 vCPU | 2 vCPU |
| **Dung lượng RAM**| 4 GiB | 8 GiB |
| **Đặc tính CPU**  | Burstable CPU (Bị giới hạn bởi CPU Credit) | Dedicated CPU (Hiệu năng thực thi độc lập ổn định) |
| **Phiên bản phần mềm** | Apache Spark 3.x / Hadoop 3.x | Apache Spark 2.4.8 / Hadoop 2.10.1 (EMR 5.36.0) |

## 4. Các thông số so sánh cốt lõi (Metrics & Benchmarks)

### A. Thời gian dựng cụm (Cluster Provisioning Time)
*   **Cụm EC2 tự dựng:** ~120 phút (Tốn nhiều thời gian do phải tạo thủ công từng máy ảo, cấu hình SSH key nội bộ, cài đặt môi trường Java, tải và giải nén các gói phần mềm Hadoop/Spark).
*   **Cụm EMR:** ~10 phút (Khởi tạo hoàn toàn tự động bằng tập lệnh AWS CLI thông qua CloudShell, toàn bộ các gói phần mềm được AWS deploy sẵn).

### B. Số bước thao tác thực hiện
*   **Cụm EC2 tự dựng:** Phức tạp (> 15 bước thao tác lệnh cấu hình thủ công hệ thống, chỉnh sửa hàng loạt file XML như `core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`).
*   **Cụm EMR:** Đơn giản (Chỉ tốn 1 bước thực thi script AWS CLI hoặc nạp trực tiếp file code vào mục Step trên Web Console).

### C. Giờ công thực hiện (Đảm bảo >= 8 giờ/tuần mỗi SV)
*   **Sinh viên Như (EMR):** 9 giờ công (Nghiên cứu tài liệu EMR, cấu hình LabRole, viết script CLI tự động hóa, thực hiện chạy benchmark các file và thu thập số liệu).
*   **Sinh viên Hiển (EC2):** 10 giờ công (Tạo hạ tầng EC2, kết nối cụm Master-Worker, chỉnh sửa file XML hệ thống, chạy tối ưu cấu hình RAM/vCPU cho Spark).

### D. Chi phí ước tính tài nguyên (AWS Cost per Hour)
*   **Cụm EC2 tự dựng:** 3 instances x $0.0416/giờ = ~$0.125 / giờ (Tiết kiệm trên lý thuyết nhưng tốn thời gian quản trị).
*   **Cụm EMR:** 3 instances x ($0.10 tiền máy EC2 + $0.05 phí dịch vụ EMR) = ~$0.450 / giờ (Chi phí theo giờ cao hơn nhưng tối ưu bằng cơ chế tự hủy cụm ngay sau khi xong tác vụ `--auto-terminate`).
