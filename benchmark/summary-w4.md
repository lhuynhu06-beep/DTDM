# Báo cáo Tổng hợp & Phân tích Kết quả Benchmark Tuần 4 - Nhóm DTD-M

## 1. Biểu đồ Thời gian chạy (Runtime) theo Kích thước Dữ liệu
* **Đường dẫn biểu đồ Runtime:** [Link biểu đồ runtime trên git](https://github.com/lhuynhu06-beep/DTDM/blob/main/docs/evidence/w4/emr-vs-self-managed-runtime.png)
* **Phân tích chi tiết:**
  - **Cụm Amazon EMR (do Lê Huỳnh Như phụ trách):** Sử dụng cấu hình tiêu chuẩn 3 node `m4.xlarge`, thời gian thực thi Job WordCount đạt mức rất ổn định và nhanh chóng, chỉ khoảng **40 giây**. Nhờ dịch vụ quản lý sẵn của AWS tự động tối ưu hóa tài nguyên phần cứng và phân phối luồng dữ liệu, thời gian xử lý không bị thắt cổ chai.
  - **Cụm Self-managed Cluster (do Hiển phụ trách):** Sử dụng instance `t3.medium` (loại CPU burstable). Thời gian thực thi dao động từ **210 giây** (đối với dữ liệu 1GB đã được tinh chỉnh cấu hình) cho đến **943 giây** (đối với baseline dữ liệu 5GB). Thời gian tăng mạnh theo kích thước dữ liệu do giới hạn phần cứng và việc phải quản lý tiến trình thủ công trên hệ thống tự dựng.

---

## 2. Bảng Công sức (Số bước, Giờ công) & Chi phí
* **Số bước công việc (Steps):** Hoàn thành toàn bộ các pipeline kiểm thử xử lý dữ liệu lớn (WordCount, Aggregation) qua các vòng lặp đánh giá hiệu năng.
* **Giờ công thực hiện:** Hoàn thành trọn vẹn các mốc thời gian theo bảng phân công (phân tích kết quả, viết hoàn thiện các chương báo cáo, dọn dẹp tài nguyên AWS).
* **Chi phí sử dụng (AWS Cost):** Tối ưu hóa trong hạn mức của tài khoản AWS Academy Learner Lab; đã thực hiện terminate cụm EMR, xóa log và dừng stack CloudFormation đúng hạn để tiết kiệm chi phí tối đa.

---

## 3. Nhận xét: Khi nào nên tự dựng vs. Khi nào nên dùng Amazon EMR?
* **Khi nào nên chọn Cụm tự dựng (Self-managed Cluster):**
  * *Phù hợp khi:* Cần nghiên cứu sâu về cấu hình hạ tầng Hadoop/Spark thủ công, học tập cách quản lý service ở tầng hệ điều hành, hoặc triển khai cho các dự án cá nhân, đồ án nghiên cứu có ngân sách hạn hẹp.
  * *Nhược điểm:* Tốn nhiều thời gian cấu hình, dễ phát sinh lỗi mạng/phân quyền, hiệu năng bị bóp nghẹt bởi giới hạn phần cứng và thiếu cơ chế tự động co giãn tài nguyên.
* **Khi nào nên chọn Amazon EMR:**
  * *Phù hợp khi:* Doanh nghiệp hoặc dự án thực tế cần xử lý khối lượng dữ liệu lớn trong thời gian ngắn (thời gian chạy nhanh gấp nhiều lần so với tự dựng), đòi hỏi tính ổn định cao, tiết kiệm thời gian vận hành và tự động hóa toàn bộ vòng đời cụm máy chủ.
  * *Nhược điểm:* Chi phí dịch vụ quản lý từ AWS cao hơn nếu không kiểm soát tốt thời gian chạy và cấu hình tài nguyên.
