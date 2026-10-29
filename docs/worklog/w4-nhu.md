**Tuần 4 (09/11–15/11/2026) Lê Huỳnh Như (24139035) – 8.5 giờ:**

- Phân tích & Tổng hợp kết quả Benchmark (3.0 giờ):
  - Vẽ biểu đồ so sánh thời gian chạy thực thi (Runtime) giữa EMR và Self-Managed theo từng mức dữ liệu (1GB, 3GB, 5GB) lưu tại `docs/evidence/w4/emr-self-managed-runtime.png`.
  - Tổng hợp bảng so sánh toàn diện về công sức (số bước khởi tạo, giờ công) và chi phí vận hành thực tế tại `benchmark/summary-w4.md`.
  - Viết đánh giá chuyên sâu: đưa ra khuyến nghị khi nào nên dùng cụm EC2 tự dựng (dự án nhỏ, tối ưu ngân sách tối đa) và khi nào nên chọn Amazon EMR (dự án doanh nghiệp, dữ liệu lớn, cần tự động co giãn và giảm giờ công vận hành).

- Soạn thảo Báo cáo tổng kết dự án (4.0 giờ):
  - Viết các chương trọng tâm: Mở đầu, Triển khai EMR (Managed Service), So sánh & Đánh giá hiệu năng/chi phí, Kết luận và Phụ lục khai báo sử dụng AI.
  - Đóng góp và ghép hoàn thiện file báo cáo tổng hợp dự án tại `docs/final.md`.

- Dọn dẹp tài nguyên & Tổng kết chi phí cuối kỳ (1.5 giờ):
  - Viết và chạy script `infra/cleanup-nhu.sh` dọn dẹp các cụm EMR, xóa log tạm, bảo lưu duy nhất thư mục kết quả cần nộp trên S3.
  - Chụp ảnh minh chứng dọn dẹp tài nguyên và tải báo cáo chi phí tổng kết AWS Learner Lab tại `docs/evidence/w4/aws-cost-report.png`.

**- Minh chứng:**
  - Biểu đồ runtime: `docs/evidence/w4/emr-self-managed-runtime.png`.
  - File tổng hợp: `benchmark/summary-w4.md`.
  - Báo cáo hoàn chỉnh: `docs/final.md`.
  - Script cleanup: `infra/cleanup-nhu.sh`.
  - Ảnh minh chứng dọn dẹp & chi phí: `docs/evidence/w4/emr-terminated.png`, `docs/evidence/w4/ec2-stopped.png`, `docs/evidence/w4/aws-cost-report.png`.

**- Khó khăn gặp phải và giải pháp:**
  - (1) Nguy cơ xóa nhầm S3 bucket chứa kết quả và bằng chứng benchmark khi chạy script dọn dẹp. 
    *Giải pháp:* Thêm điều kiện kiểm tra và xác nhận thủ công trong script `infra/cleanup-nhu.sh` để bảo vệ thư mục `/results/`.

**Phần có AI hỗ trợ (Như):**
- Công cụ / model: Claude (Claude 3.5 Sonnet).
- Prompt chính: *"Viết script shell (cleanup-nhu.sh) dùng AWS CLI để kiểm tra và xóa tự động các cụm EMR, xóa file log trên S3 nhưng giữ lại thư mục kết quả /results/"*.
- Nội dung AI tạo: Mẫu script shell tự động kiểm tra danh sách EMR clusters và gọi lệnh `aws emr terminate-clusters` kèm lệnh dọn dẹp S3 log prefix.
- Phần đã tự sửa/kiểm tra: Kiểm tra điều kiện thực tế, thêm các bước xác nhận trước khi xóa để tránh xóa nhầm dữ liệu minh chứng cần nộp; tự chạy lệnh kiểm thử trên AWS CloudShell và chụp ảnh bằng chứng cụm EMR đã Terminated.
