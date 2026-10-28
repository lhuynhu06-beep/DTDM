**Tuần 2 (26/10–01/11/2026)** **Lê Huỳnh Như (24139035) – 10 giờ công:**

- Viết file script tự động hóa AWS CLI run-emr-benchmark-Nhu.sh tích hợp tham số tự động hủy cụm khi nhàn rỗi (--auto-terminate) để tối ưu chi phí.
- Upload file truyện văn học Việt Nam ChiPheo.txt vào phân vùng data/ và mã nguồn xử lý vào jobs/ trên Amazon S3 bucket hadoop-spark-lab-24139035.
- Thực thi kịch bản tạo cụm tự động hóa qua AWS CloudShell. Ghi nhận hệ thống chạy Step WordCount xử lý tệp tin ChiPheo.txt thành công xuất sắc trong vòng 50 giây.
- Xuất kết quả đếm từ thực tế về thư mục kết quả chỉ định results/emr/ trên S3 và đồng bộ file part-00000 lên kho lưu trữ GitHub của nhóm.
- Gặp lỗi kỹ thuật: Do chạy script liên tiếp dẫn đến hiện tượng quá tải vCPU Quotas (giới hạn 32 vCPU của Learner Lab) khiến các cụm sau bị báo lỗi Échec d'instance. Đã khắc phục bằng cách giải phóng cụm lỗi và chuyển sang cơ chế chạy tuần tự.

**Kế hoạch tuần sau (Như):** Phát triển thêm kịch bản kiểm thử cho tác vụ Data Aggregation, nâng mức tải tập tin lớn và theo dõi giám sát qua hệ thống giám sát CloudWatch.

**Phần có AI hỗ trợ (Như):**
- Công cụ: Gemini.
- Prompt chính: "Sửa lỗi cú pháp truyền đối số Args trong tham số --steps của lệnh aws emr create-cluster".
- Nội dung AI tạo: Gợi ý cú pháp mảng phân tách bằng dấu phẩy và thêm dấu gạch chéo kết thúc đường dẫn thư mục đầu ra S3.
- Phần đã tự sửa/kiểm tra: Đã rà soát lại toàn bộ đường dẫn thư mục S3 thật, tự chạy lệnh kiểm chứng ra file kết quả _SUCCESS.
