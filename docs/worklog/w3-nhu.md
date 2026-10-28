**Tuần 3 (02/11–08/11/2026)** **Lê Huỳnh Như (24139035) – 9 giờ công:**

- Triển khai giải pháp bảo mật và giám sát hệ thống: Cấu hình Block Public Access cho S3 bucket và cấu hình thu thập 3 chỉ số đo lường cốt lõi trên CloudWatch Metrics (IsIdle, AppsRunning, HDFSUtilization).
- Chụp ảnh lưu trữ đầy đủ 3 minh chứng bảo mật vào đúng đường dẫn docs/evidence/w3/ theo yêu cầu.
- Lập bảng tính toán chi phí tài nguyên thực tế tiêu tốn dựa trên hóa đơn On-Demand tích lũy của buổi làm Lab (~1.0 giờ EMR, ~2.0 giờ EC2) lưu tại file benchmark/cost.csv với tổng thiệt hại thực tế chỉ $0.71 USD.
- Tiến hành thực hiện đối chéo kịch bản: Chạy thử nghiệm thành công cụm tự dựng 3 Node t3.medium theo bộ tài liệu cấu hình của sinh viên Hiển.
- Hoàn thiện bảng so sánh nháp dữ liệu thô sơ bộ gửi giảng viên kiểm tra tiến độ.

**Kế hoạch tuần sau (Như):** Kết hợp với Hiển viết báo cáo hoàn chỉnh chương final.md, tổng hợp nhận xét cấu hình phần cứng và hoàn thiện video demo dự án.

**Phần có AI hỗ trợ (Như):**
- Công cụ: Gemini.
- Prompt chính: "Lọc các chỉ số EMR đã tắt trong giao diện biểu đồ CloudWatch Metrics".
- Nội dung AI tạo: Hướng dẫn tìm kiếm từ khóa cục bộ và chuyển đổi giao diện xem Graphed Metrics.
- Phần đã tự sửa/kiểm tra: Tự tay tích chọn đúng mã ID cụm j-0054312342KWHFQCHN5M để biểu đồ hiển thị chính xác đồ thị trực quan.
