**Tuần 4 (09/11–15/11/2026)**: phần của Đỗ Minh Hiển (24139013)
*(Ghi chú trung thực: kiểm thử tổng thể, tối ưu và bản nháp các chương làm ngày 25/10/2026; quay demo và dọn dẹp làm sau khi nhóm thống nhất.)*

**Đỗ Minh Hiển (24139013) – … giờ:**
- **Kiểm thử tổng thể:** dựng cụm từ đầu bằng CloudFormation (`hadoop-cfn`, 4 phút 37 giây).
  - Trên cụm mới đã chạy aggregation 1/3/5 GB × 3 lần, đọc thẳng dữ liệu từ S3 và ghi kết quả vào `results/self-managed/`.
  - Đã kiểm tra tính đúng của kết quả:
    - WordCount ra đúng **6.000 từ khác nhau**, bằng kích thước từ vựng sinh ra.
    - Aggregation ra **12 vùng**, mỗi vùng khoảng 1,6 triệu dòng (tổng khoảng 19,2 triệu dòng cho 1 GB).
    - Cần đối chiếu với kết quả EMR của Như: dùng cùng dữ liệu và cùng job.
- **Tối ưu Spark** (`benchmark/run-tuning.sh`): so sánh trên CÙNG một cụm, WordCount 1 GB × 3 lần.
  - *Trước:* 3 executor × 1 core, mỗi executor 1g; driver 1g. File 128 MB chia thành 8 task chạy trên 3 core, tức 3 đợt và đợt cuối bỏ trống 1 core.
  - *Sau:* 2 executor × 2 core, mỗi executor 1600m; driver 512m. Như vậy có 4 core. Thêm `maxPartitionBytes=64m`, nên 16 task được chia đều hơn.
  - **Kết quả: 231,4 s → 210,0 s (−9,3%)**, độ lệch chuẩn ≤ 2 s. Mức giảm nhỏ hơn mức tăng số core (+33%) vì mỗi worker chỉ có 2 vCPU, phải chia cho cả Python worker lẫn JVM.
- **Các chương báo cáo** (`report/chuong-self-managed-hien.md`): A. Kiến trúc Hadoop/Spark; B. Triển khai cụm tự dựng; C. IaC CloudFormation; D. Bảo mật & giám sát; E. Kết quả benchmark.
- **Demo:** kịch bản khoảng 4 phút trong `docs/demo-script-self-managed.md`. Clip demo: … *(Hiển tự quay)*
- **Dọn dẹp:** chạy `infra/cleanup.sh` để liệt kê (dry-run) rồi `--yes` để xoá stack CFN, 3 EC2 và EBS, SG, dashboard/alarm, `data/` và `artifacts/`. Giữ lại `results/` để nộp.
  - Ảnh console sau khi xoá: … *(điền sau khi chạy)*

**Phần có AI hỗ trợ:** Claude (Anthropic), claude-opus-5-5.
- AI tạo: script tối ưu, script tổng hợp kết quả và vẽ biểu đồ, bản nháp các chương báo cáo, kịch bản demo, script dọn dẹp.
- Hiển tự kiểm tra: … *(điền)*
