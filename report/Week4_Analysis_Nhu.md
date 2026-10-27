# PHÂN TÍCH KẾT QUẢ & SO SÁNH HIỆU NĂNG - TUẦN 4

## 1. Biểu đồ thời gian chạy (Runtime Analysis)
* **Mô hình Self-Managed (EC2 tự dựng):** Thời gian thực thi kéo dài hơn khi dung lượng dữ liệu tăng do giới hạn tài nguyên phần cứng đơn lẻ và chi phí truyền nhận dữ liệu qua mạng.
* **Mô hình Amazon EMR:** Tốc độ xử lý nhanh và ổn định nhờ cụm phân tán 3 nodes (`m4.xlarge`), tận dụng tối đa cơ chế bộ nhớ trong (in-memory computation) của Apache Spark.

## 2. Bảng tổng hợp công sức & Chi phí
| Tiêu chí | Self-Managed EC2 | Amazon EMR |
| :--- | :--- | :--- |
| **Số bước thực hiện (Steps)** | Phức tạp (Cài đặt thủ công Java, Hadoop, Spark, XML) | Đơn giản (Tạo cụm và Submit Step Job) |
| **Tổng giờ công (Setup & Debug)** | ~ 6 - 8 giờ | ~ 1 - 2 giờ |
| **Chi phí hạ tầng (AWS Billing)** | Tối ưu cho môi trường Lab/Thử nghiệm | Tối ưu hóa thời gian kỹ sư và vận hành |

## 3. Nhận xét & Đánh giá
* **Khi nào nên tự dựng (Self-Managed):** Cho mục đích học tập, nghiên cứu sâu kiến trúc bên trong của hệ thống phân tán, hoặc hệ thống chạy liên tục 24/7 với cấu hình cố định.
* **Khi nào nên dùng Amazon EMR:** Cho các bài toán Big Data thực tế trong doanh nghiệp cần xử lý theo đợt (batch), cần triển khai nhanh chóng và khả năng tự động co giãn (Auto-scaling).
