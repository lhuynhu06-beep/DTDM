##  Bảng so sánh nháp thông số hệ thống (Sơ bộ Tuần 3)

Dưới đây là bảng đối chiếu số liệu thực nghiệm sơ bộ giữa hai giải pháp tính toán (Dữ liệu gốc dựa trên tệp văn bản ChiPheo.txt ở mức dữ liệu <1GB):

| Tiêu chí so sánh | Cụm tự dựng (Self-managed EC2) | Cụm Dịch vụ (Amazon EMR) |
| :--- | :--- | :--- |
| **Loại cấu hình Instance** | t3.medium (4GB RAM, Burstable) | m4.large (8GB RAM, Dedicated) |
| **Thời gian dựng cụm** | ~120 phút (Thủ công) | ~10 phút (Tự động hóa hoàn toàn) |
| **Số bước thao tác lệnh** | Phức tạp (> 15 lệnh cấu hình XML) | Đơn giản (1 lệnh AWS CLI/Console Step) |
| **Thời gian chạy WordCount** | 224 giây (Cấu hình mặc định Baseline) | **50 giây** (Đã được AWS tối ưu sẵn) |
| **Giờ công thực hiện/Tuần** | 10 giờ công (Sinh viên Hiển) | 9 giờ công (Sinh viên Như) |
| **Tổng chi phí Lab thực tế**| $0.25 USD (Chạy tích lũy ~2.0 giờ) | $0.46 USD (Chạy tích lũy ~1.0 giờ) |
| **Cơ chế quản lý dữ liệu** | Lưu trên ổ HDFS cục bộ (Dễ mất dữ liệu) | Tích hợp EMRFS đọc/ghi trực tiếp từ S3 |
