**Tuần 4 (09/11–15/11/2026)** **Lê Huỳnh Như (24139035) – 8.5 giờ công:**

- Thực hiện tổng kết dự án: Phân tích kết quả thực nghiệm lịch sử chạy từ tệp results.csv, viết báo cáo nhận xét chi tiết trường hợp tối ưu hóa hạ tầng tính toán (khi nào dùng EC2 tự dựng và khi nào dùng Amazon EMR).
- Phối hợp với Hiển tổng hợp toàn bộ các chương nội dung (Mở đầu, Triển khai EMR, So sánh, Kết luận) để hoàn thiện file báo cáo tổng kết cuối kỳ chính thức docs/final.md.
- Hoàn thành quy trình dọn dẹp tài nguyên hạ tầng cuối kỳ (Clean up): Tiến hành Terminate toàn bộ các cụm EMR benchmark để giải phóng vCPU và chụp ảnh minh chứng lưu trữ tại docs/evidence/w4/emr-terminated_1.png.
- Truy cập AWS Billing Console để trích xuất báo cáo hóa đơn thực tế của toàn bộ vòng đời bài tập lớn, lưu minh chứng aws-cost-report_1.png.

**Kết quả thu hoạch:** Hoàn thành mục tiêu bài tập lớn đối chứng dữ liệu phân tán, tất cả các link file trên GitHub đều sáng và hoạt động tốt.

**Phần có AI hỗ trợ (Như):**
- Công cụ: Gemini, ChatGPT.
- Prompt chính: "Tóm tắt các luận điểm so sánh cốt lõi giữa Dedicated vCPU của EMR và Burstable vCPU của EC2 để đưa vào chương kết luận báo cáo".
- Nội dung AI tạo: Gợi ý các từ khóa về tính tuyến tính của hiệu năng xử lý dữ liệu tải cao.
- Phần đã tự sửa/kiểm tra: Tự rà soát toàn bộ cấu trúc bảng số liệu thực tế, kiểm tra trạng thái xóa tài nguyên trên EC2 Console để đảm bảo an toàn ví tiền Lab.
