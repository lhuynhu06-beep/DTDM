**Tuần 1 (19/10–25/10/2026)** **Lê Huỳnh Như (24139035) – 9 giờ công:**

- Tìm hiểu cơ chế dịch vụ quản lý Amazon EMR và giao thức lưu trữ đối tượng Amazon S3 kết hợp EMRFS.
- Khởi tạo thành công cụm EMR thủ công trên giao diện Web Console (phiên bản 5.36.0) sử dụng cấu hình phần cứng 3 Node máy ảo thế hệ m4.large (1 Primary + 2 Core).
- Cấu hình phân quyền Identity and Access Management (IAM) bắt buộc cho môi trường Learner Lab bao gồm Service Role gán cho EMR_DefaultRole và EC2 Instance Profile gán cho EMR_EC2_DefaultRole.
- Chụp ảnh minh chứng Tuần 1: Tổng quan trạng thái cụm EMR hiển thị rõ phiên bản phần mềm emr-5.36.0 và mã số tài khoản học viên chính chủ ở góc phải màn hình.
- Tiến hành Terminate cụm máy ảo ngay sau khi lấy đủ ảnh cấu hình để bảo toàn ngân sách credits tài khoản.

**Kế hoạch tuần sau (Như):** Thiết kế kịch bản lệnh tự động hóa AWS CLI, viết mã nguồn Python tác vụ WordCount kết nối trực tiếp với S3 để chuẩn bị đo lường hiệu năng.

**Phần có AI hỗ trợ (Như):**
- Công cụ: Gemini, ChatGPT.
- Prompt chính: "Hướng dẫn cấu hình quyền IAM Role cho cụm Amazon EMR 5.36.0 trên tài khoản AWS Learner Lab bị giới hạn quyền".
- Nội dung AI tạo: Bản dịch các thuật ngữ gán quyền từ tiếng Pháp sang tiếng Anh và gợi ý trỏ quyền sang các policy có sẵn.
- Phần đã tự sửa/kiểm tra: Đã tự thao tác tích chọn thủ công các lớp cấu hình mạng và quyền hệ thống trực tiếp trên AWS Console thành công.
