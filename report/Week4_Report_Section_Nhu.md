# NỘI DUNG BÁO CÁO TỔNG KẾT TUẦN 4
**Người thực hiện:** Lê Huỳnh Như - MSSV: 24139035

## 1. Mở đầu
* Tổng quan về bài toán xử lý dữ liệu lớn (Big Data) trên hạ tầng đám mây AWS.
* Mục tiêu: So sánh hiệu năng, đánh giá công sức vận hành và kiểm soát chi phí thực tế giữa hai mô hình tự dựng (Self-managed) và dịch vụ quản lý (Amazon EMR).

## 2. Triển khai Amazon EMR
* Dựng cụm Amazon EMR tiêu chuẩn (1 Primary, 2 Core nodes `m4.xlarge`) trong AWS Learner Lab.
* Tích hợp lưu trữ Amazon S3, cấu hình phân quyền IAM Roles và chạy thành công tác vụ WordCount.

## 3. So sánh & Đánh giá
* Tổng hợp số liệu từ các tập tin `results.csv` và `cost.csv`.
* Đánh giá chi tiết ưu/nhược điểm về chi phí, thời gian triển khai và độ phức tạp vận hành của hai kiến trúc.

## 4. Kết luận & Dọn dẹp tài nguyên
* Hoàn tất dọn dẹp hạ tầng: Terminate cụm EMR và giải phóng các EC2 instances để kiểm soát ngân sách.
* Rút ra bài học thực tế về quy trình triển khai và tối ưu hóa hệ thống Big Data trên mây.

## 5. Phụ lục: Khai báo AI (AI Disclosure)
* Trợ lý AI (Gemini) được sử dụng để hỗ trợ kiểm tra cú pháp file CSV, định hình cấu trúc báo cáo Markdown và chuẩn hóa tài liệu kỹ thuật.
