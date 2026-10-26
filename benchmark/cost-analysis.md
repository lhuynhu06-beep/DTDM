#  Báo Cáo Phân Tích & So Sánh Chi Phí Cụm (Cost Analysis)

## 1. Bảng Tổng Hợp So Sánh Trực Quan

| Tiêu chí so sánh | Cụm Self-Managed (EC2) | Cụm Managed (AWS EMR) | Đánh giá & Chênh lệch |
| :--- | :--- | :--- | :--- |
| **Loại Instance** | `t3.medium` | `m4.xlarge` | EMR dùng cấu hình lớn hơn |
| **Thông số / Node** | 2 vCPU, 4GB RAM | 4 vCPU, 16GB RAM | EMR gấp 2vCPU & 4 lần RAM |
| **Số lượng Node** | 3 (1 Master + 2 Workers) | 3 (1 Master + 2 Core) | Bằng nhau về số lượng |
| **Giá EC2 ($/giờ)** | $0.1248 | $0.6000 | EC2 EMR đắt hơn do cấu hình |
| **Phí Dịch vụ EMR**| $0.0000 | $0.1800 | $0.06 / node / giờ |
| **Tổng Chi Phí / Giờ**| **$0.1248** | **$0.7800** | **EMR đắt hơn ~6.25 lần** |

---

## 2. Nhận Xét Chi Tiết

###  2.1. Cụm Self-Managed (`t3.medium`)
* **Chi phí thực tế:** Mức chi phí **$0.1248 / giờ** vô cùng tối ưu[cite: 7].
* **Đánh giá Ngân sách:** Thực thi đủ 24 lượt benchmark thực tế chỉ tiêu tốn ngân sách rất nhỏ (~$1.5 - $3.0), hoàn toàn an toàn cho hạn mức $100 budget của tài khoản AWS Academy Learner Lab[cite: 1, 7].

###  2.2. Cụm EMR (`m4.xlarge`)
* **Chi phí ước tính:** Mức chi phí **$0.7800 / giờ** (bao gồm $0.6000 tiền EC2 + $0.1800 phí quản lý EMR)[cite: 7].
* **Chênh lệch:** Chi phí EMR cao hơn 6.25 lần do phần cứng mạnh vượt trội kèm theo phụ phí dịch vụ EMR của AWS[cite: 7].

---

## 3. Ghi Chú Về Giới Hạn Hệ Thống Sandbox

| Nội dung | Chi tiết trạng thái |
| :--- | :--- |
| **Trạng thái EMR** | Không khởi tạo được do tài khoản AWS Academy Sandbox bị chặn quyền API `elasticmapreduce:RunJobFlow`[cite: 1, 7]. |
| **Dữ liệu Benchmark** | Ghi nhận `N/A` cho EMR trong file kết quả; tập trung phân tích 24 lượt chạy từ cụm Self-Managed[cite: 1, 7]. |
| **Bảng giá EMR** | Tính toán chuẩn xác theo giá niêm yết công khai On-Demand của AWS tại vùng `us-east-1`[cite: 7]. |
