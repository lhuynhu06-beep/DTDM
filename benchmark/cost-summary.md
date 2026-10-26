# 📊 Báo Cáo Tổng Kết Chi Phí & Tối Ưu Hạ Tầng (Cost Summary Report)

---

## 1. Tóm Tắt Ngân Sách Thực Tế (AWS Academy Learner Lab)

* **Ngân sách Sandbox được cấp:** $100.00 Credit (Quỹ ảo trong môi trường Lab)[cite: 1].
* **Chi phí tiêu tốn thực tế ước tính:** **~$2.50 / $100.00** (~2.5% tổng ngân sách)[cite: 1].
* **Trạng thái tài khoản:** An toàn 100%, không bị gián đoạn service hay nguy cơ vượt budget[cite: 1].

---

## 2. Bảng Phân Tích & So Sánh Chi Phí Trực Quan (Hourly Rate)

| Tiêu chí so sánh | Cụm Tự Dựng Self-Managed (Thực tế) | Cụm Quản Lý AWS EMR (Ước tính) | Đánh giá & Chênh lệch |
| :--- | :--- | :--- | :--- |
| **Loại Instance** | `t3.medium` | `m4.xlarge` | EMR dùng phần cứng lớn hơn |
| **Cấu hình / Node** | 2 vCPU, 4GB RAM | 4 vCPU, 16GB RAM | EMR gấp 2 vCPU & 4 lần RAM |
| **Số lượng Node** | 3 (1 Master + 2 Worker) | 3 (1 Master + 2 Core) | Số lượng node tương đương |
| **Giá EC2 ($/giờ)** | $0.1248 ($0.0416/node) | $0.6000 ($0.2000/node) | Chi phí EC2 EMR cao hơn |
| **Phí Dịch vụ EMR** | $0.0000 | $0.1800 ($0.0600/node) | Phí quản lý dịch vụ AWS |
| **Tổng Chi Phí / Giờ** | **$0.1248 / giờ** | **$0.7800 / giờ** | **EMR đắt hơn ~6.25 lần** |

---

## 3. Đánh Giá & Nhận Xét Chi Tiết

### 3.1. Cụm Self-Managed (`t3.medium`)
* **Tối ưu ngân sách:** Mức chi phí **$0.1248 / giờ** cực kỳ tiết kiệm. 
* **Hiệu quả thực thi:** Thực hiện trọn vẹn 24 lượt test benchmark chỉ tiêu tốn ngân sách rất nhỏ (~$2.50), hoàn toàn tối ưu cho môi trường học tập[cite: 1].

### 3.2. Cụm AWS EMR (`m4.xlarge`)
* **Chi phí ước tính:** Mức chi phí **$0.7800 / giờ** ($0.6000 EC2 + $0.1800 phí EMR).
* **Đánh giá quy mô:** Đắt hơn 6.25 lần do cấu hình mạnh vượt trội kèm phụ phí quản lý. Phù hợp cho bài toán Big Data doanh nghiệp lớn cần Auto-scaling tự động hơn là môi trường học tập.

---

## 4. Giải Trình Giới Hạn Môi Trường Sandbox

* **Giới hạn API:** Tài khoản AWS Academy Learner Lab bị khóa quyền `elasticmapreduce:RunJobFlow`, do đó không thể khởi tạo cụm EMR thực tế[cite: 1].
* **Xử lý dữ liệu:** Kết quả benchmark EMR được ghi nhận `N/A` trong file `results-self-managed.csv`[cite: 1].
* **Tính chính xác chi phí:** Bảng giá EMR được tra cứu chuẩn xác theo bảng giá On-Demand công khai của AWS tại vùng `us-east-1`.

---

## 5. Quy Trình Dọn Dẹp Resource Bảo Tồn Ngân Sách

* **EC2 Instance:** Đã thực hiện `Stop` toàn bộ các máy chủ (`Bastion Host` & `Lab Instance`) ngay sau khi hoàn tất đo đạc để cắt ngắt chi phí theo giờ.
* **S3 Bucket:** Đã dọn dẹp log tạm, lưu giữ trọn vẹn thư mục mã nguồn (`jobs/`), dữ liệu (`data/`) và kết quả đo đạc trên GitHub repo để nộp bài.
