# BÁO CÁO ĐỒ ÁN MÔN HỌC CLOUD
## Đề tài: Triển khai cụm Hadoop/Spark tự dựng trên EC2 và so sánh hiệu năng, chi phí với Amazon EMR

**Môn học:** Điện toán đám mây (Cloud) – Đợt 1 (2026–2027)  
**Giảng viên hướng dẫn:** Huỳnh Xuân Phụng (phunghx@hcmute.edu.vn)  
**Thời lượng thực hiện:** 4 tuần (05/10/2026 – 31/10/2026)  
**Repository GitHub:** [https://github.com/lhuynhu06-beep/DTDM](https://github.com/lhuynhu06-beep/DTDM)  

### Thành viên thực hiện:
| STT | Họ và tên | Mã số sinh viên | Vai trò | Phân công chính |
| :-: | :--- | :-: | :--- | :--- |
| 1 | **Lê Huỳnh Như** | 24139035 | Trưởng nhóm | Nhánh Managed (EMR, S3), Viết PySpark Jobs, Benchmark & Báo cáo chi phí/tổng hợp |
| 2 | **Đỗ Minh Hiển** | 24139013 | Thành viên | Nhánh Self-managed (EC2, HDFS, YARN), Spark-on-YARN, IaC (CloudFormation), Monitoring |


## CHƯƠNG 1: TỔNG QUAN & RÀNG BUỘC KỸ THUẬT

### 1.1. Mục tiêu đồ án
Đồ án nhằm mục đích xây dựng, thực nghiệm và so sánh toàn diện hai mô hình triển khai hạ tầng xử lý dữ liệu lớn (Big Data) trên hạ tầng điện toán đám mây Amazon Web Services (AWS):
1. **Mô hình Tự quản lý (Self-Managed Cluster):** Tự khởi tạo các máy chủ ảo EC2, cài đặt và cấu hình thủ công/IaC cụm Apache Hadoop (HDFS, YARN) và Apache Spark.
2. **Mô hình Dịch vụ quản lý (Managed Service):** Sử dụng dịch vụ Amazon Elastic MapReduce (EMR) để khởi chạy cụm Spark/Hadoop tự động hóa.

### 1.2. Tuân thủ ràng buộc kỹ thuật & Quy tắc vận hành
- **Dịch vụ sử dụng:** Chỉ sử dụng 3 dịch vụ cốt lõi: Amazon EC2, Amazon EMR và Amazon S3.
- **Khu vực (Region):** Duy trì cố định tại `us-east-1` (US East - N. Virginia) nhằm tương thích với key pair `vockey` có sẵn của AWS Learner Lab.
- **Giới hạn hạn ngạch (Quota & Safety Limit):** Cam kết không chạy đồng thời cụm Self-Managed và cụm EMR để không vượt quá giới hạn 9 EC2 instances và 32 vCPU của Learner Lab. Nhóm thông báo qua channel trao đổi trước khi bật cụm.
- **Phân quyền & Bảo mật (IAM):** Sử dụng các Role/Instance Profile có sẵn (`LabRole`, `LabInstanceProfile`, `EMR_DefaultRole`, `EMR_EC2_LabRole`). Không tạo mới IAM User/Role.
- **Gắn nhãn tài nguyên (Tagging):** Mọi tài nguyên khởi tạo đều bắt buộc gắn nhãn:
  - `Project=HadoopSpark-EC2-vs-EMR`
  - `Owner=<MSSV_Nguoi_Tao>` (24139035 hoặc 24139013)
- **Tối ưu chi phí & Quản lý Lab Session:** Thực hiện dừng (`Stop EC2`) hoặc xóa (`Terminate EMR`) tài nguyên ngay sau mỗi buổi làm việc. Theo dõi ngân sách AWS Learner Lab thường xuyên.


## CHƯƠNG 2: KIẾN TRÚC HỆ THỐNG & KẾ HOẠCH TRIỂN KHAI

### 2.1. Sơ đồ kiến trúc hạ tầng

#### a) Mô hình Cụm Tự Dựng (Self-Managed on EC2)
- **Master Node (1 instance `t3.medium`):** Đảm nhận NameNode (HDFS) và ResourceManager (YARN).
- **Worker Nodes (2 instances `t3.medium`):** Đảm nhận DataNode (HDFS) và NodeManager (YARN).
- **Lưu trữ & Connector:** Mỗi node trang bị 30 GB EBS (`gp3`). Cấu hình Spark S3A Connector (`hadoop-aws` + `aws-java-sdk-bundle`) để đọc/ghi dữ liệu trực tiếp với S3.
- *Sơ đồ kiến trúc:* `docs/diagrams/self-managed-architecture.png`

#### b) Mô hình Cụm Quản Lý (Amazon EMR)
- **Primary Node (1 instance `m4.large`):** Điểm điều phối cụm EMR.
- **Core Nodes (2 instances `m4.large`):** Lưu trữ HDFS cục bộ và thực thi YARN Task Executors.
- **Tích hợp:** Đọc/ghi dữ liệu trực tiếp với Amazon S3 qua EMRFS.


### 2.2. Kế hoạch triển khai 4 tuần & Worklog nhóm

Mỗi thành viên đảm bảo thời lượng thực hiện $\ge$ 8 giờ/tuần. Nhóm đã phân công theo 2 nhánh song song (Self-managed và Managed) kết hợp kiểm tra đổi chéo để cả hai thành viên đều nắm vững toàn bộ kiến thức hệ thống.

#### Bảng tổng hợp công việc & Báo cáo 4 tuần:

| Tuần | Sinh viên thực hiện | Nội dung công việc | Số giờ | Minh chứng / Worklog đính kèm |
| :-: | :--- | :--- | :-: | :--- |
| **Tuần 1** | Lê Huỳnh Như | Khởi tạo repo Git, bucket S3 (`data/`, `jobs/`, `results/`), cấu hình Block Public Access & Tag. Chuẩn bị dữ liệu text/csv (1GB, 3GB, 5GB). Viết job PySpark `wordcount.py`, `aggregation.py` và chạy thử local. | **8.0h** | `docs/worklog/w1-nhu.md`<br>`jobs/wordcount.py` |
| **Tuần 1** | Đỗ Minh Hiển | Tìm hiểu kiến trúc Hadoop/YARN, vẽ sơ đồ Self-managed. Khởi tạo 3 EC2 `t3.medium`, gắn `LabInstanceProfile`, cấu hình `/etc/hosts`, SSH passwordless, cài Java 11, Hadoop 3.3, Spark 3.5. | **9.0h** | `docs/worklog/w1-hien.md`<br>`scripts/setup-base.sh` |
| **Tuần 2** | Lê Huỳnh Như | Tạo cụm EMR (emr-6.10.x, 1 primary + 2 core). Submit Spark Step, kiểm tra kết quả S3. Viết script CLI `infra/emr-create.sh` tự động ngắt cụm `--auto-terminate`. Thống nhất `benchmark/plan.md`. | **9.0h** | `docs/worklog/w2-nhu.md`<br>`infra/emr-create.sh` |
| **Tuần 2** | Đỗ Minh Hiển | Cấu hình HDFS, YARN trên 3 EC2. Tinh chỉnh bộ nhớ. Cấu hình S3A Connector đọc/ghi S3. Chạy test job WordCount. Viết script cài đặt `install-hadoop.sh`, `start-cluster.sh`. | **10.5h** | `docs/worklog/w2-hien.md`<br>`conf/hadoop/*`, `conf/spark/*` |
| **Tuần 3** | Lê Huỳnh Như | Cấu hình bảo mật S3 Block Public Access & mã hóa SSE-S3. Giám sát EMR bằng CloudWatch metrics (`IsIdle`, `AppsRunning`). Chạy benchmark EMR (18 lượt). Lập bảng chi phí nháp. | **8.5h** | `docs/worklog/w3-nhu.md`<br>`benchmark/summary-emr.md` |
| **Tuần 3** | Đỗ Minh Hiển | Viết template CloudFormation `infra/self-managed.yaml` dựng cụm tự động trong 4m37s. Cấu hình Security Group, SSH tunnel, CloudWatch Agent (CPU, RAM, Disk). Chạy benchmark Self-managed (24 lượt). | **9.5h** | `docs/worklog/w3-hien.md`<br>`infra/self-managed.yaml` |
| **Tuần 4** | Lê Huỳnh Như | Tổng hợp kết quả benchmark, vẽ biểu đồ so sánh Runtime, lập bảng so sánh công sức & chi phí. Thực hiện kiểm tra đổi chéo cụm tự dựng. Ghép báo cáo hoàn chỉnh `docs/final.md`. Dọn dẹp S3, EMR. | **8.5h** | `docs/worklog/w4-nhu.md`<br>`benchmark/summary-w4.md` |
| **Tuần 4** | Đỗ Minh Hiển | Kiểm thử tổng thể cụm. Tinh chỉnh tham số Spark (`spark.executor.memory`, `shuffle.partitions`) giúp giảm ~9.3% runtime. Quay video demo cụm tự dựng. Dọn dẹp stack CloudFormation, EC2, EBS. | **8.5h** | `docs/worklog/w4-hien.md`<br>`infra/cleanup.sh` |

#### Tổng kết giờ công toàn khóa:
- **Lê Huỳnh Như:** $8.0 + 9.0 + 8.5 + 8.5 = \mathbf{34.0\text{ giờ}}$ (Trung bình **8.5 giờ/tuần**)
- **Đỗ Minh Hiển:** $9.0 + 10.5 + 9.5 + 8.5 = \mathbf{37.5\text{ giờ}}$ (Trung bình **9.4 giờ/tuần**)
- **Kết luận:** Cả hai thành viên đều hoàn thành vượt định mức yêu cầu tối thiểu ($\ge$ 8.0 giờ/tuần). Các đường dẫn nhật ký công việc (`docs/worklog/`) đều đã được cập nhật đầy đủ lên repository GitHub.


## CHƯƠNG 3: KẾT QUẢ THỰC NGHIỆM & PHÂN TÍCH SO SÁNH

### 3.1. Bảng số liệu Benchmark Runtime (Thời gian tính bằng giây)

Thử nghiệm được thực hiện trên 3 mức dữ liệu (1GB, 3GB, 5GB) cho 2 bài toán **WordCount** và **Aggregation** (Group-By Sum). Mỗi trường hợp chạy 3 lần lấy giá trị trung bình.

| Dung lượng | Bài toán (Job) | Self-Managed (Trước tối ưu) | Self-Managed (Sau tối ưu) | Amazon EMR | Chênh lệch (EMR vs SM Sau TƯ) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **1 GB** | **WordCount** | 231.4 s | **210.0 s** | **142.5 s** | EMR nhanh hơn **32.1%** |
| **1 GB** | **Aggregation** | 185.0 s | **168.2 s** | **112.0 s** | EMR nhanh hơn **33.4%** |
| **3 GB** | **WordCount** | 645.2 s | **588.0 s** | **385.0 s** | EMR nhanh hơn **34.5%** |
| **3 GB** | **Aggregation** | 512.0 s | **465.5 s** | **302.0 s** | EMR nhanh hơn **35.1%** |
| **5 GB** | **WordCount** | 1,080.5 s | **982.0 s** | **635.0 s** | EMR nhanh hơn **35.3%** |
| **5 GB** | **Aggregation** | 860.0 s | **780.0 s** | **501.0 s** | EMR nhanh hơn **35.8%** |

> **Hình ảnh minh chứng biểu đồ Runtime:** `docs/evidence/w4/emr-vs-self-managed-runtime.png`

#### Nhận xét hiệu năng:
1. **Amazon EMR vượt trội từ 32% – 36%:** Nhờ tích hợp sẵn **EMR Runtime for Apache Spark** tối ưu hóa tầng I/O và cấu hình phần cứng `m4.large` (8 GiB RAM/node), EMR hoàn thành công việc nhanh hơn đáng kể so với cụm EC2 `t3.medium` (4 GiB RAM/node).
2. **Khả năng mở rộng (Scalability):** Khi dung lượng dữ liệu tăng gấp 5 lần (từ 1GB lên 5GB), thời gian thực thi của cả hai hệ thống tăng tuyến tính, nhưng đường độ dốc của EMR thấp hơn, chứng tỏ hiệu quả xử lý dữ liệu lớn tốt hơn.
3. **Kết quả tối ưu Spark:** Nhờ tinh chỉnh `spark.executor.memory`, `spark.driver.memory` và `spark.sql.shuffle.partitions`, cụm tự dựng đã rút ngắn được **~9.3%** thời gian chạy so với ban đầu.


### 3.2. So sánh Công sức triển khai & Vận hành (Operational Effort)

| Tiêu chí | Self-Managed (EC2) | Amazon EMR |
| :--- | :--- | :--- |
| **Thời gian dựng cụm từ đầu** | Thủ công: 2–3 giờ.<br>Tự động hóa IaC (CloudFormation): **4 phút 37 giây**. | Khởi tạo tự động qua CLI/Console: **5–7 phút**. |
| **Cài đặt & Cấu hình** | **Phức tạp:** Phải cấu hình thủ công Java, HDFS, YARN, Spark, S3A Connector, SSH tunnel. | **Đơn giản:** AWS tự động cấu hình và tối ưu hóa sẵn toàn bộ stack Hadoop/Spark. |
| **Giám sát & Bảo trì** | Cài thêm CloudWatch Agent, tự theo dõi log Daemon, tự khắc phục sự cố node. | Coi trực tiếp trên EMR Console, hỗ trợ các chỉ số `IsIdle`, `AppsRunning`, `HDFSUtilization`. |
| **Co giãn tài nguyên (Scaling)** | Phải viết script cấu hình thủ công node mới vào YARN cluster. | Hỗ trợ Auto-scaling linh hoạt hoặc điều chỉnh số lượng Core/Task node qua CLI. |


### 3.3. Báo cáo Chi phí thực tế trên AWS Billing (AWS Cost Report)

Dựa trên số liệu ghi nhận thực tế từ AWS Billing Console (Account ID: `9337-3325-7957` / `24139035@student.hcmute.edu.vn`):

- **Tổng chi phí thực tế tiêu tốn (Cost MTD):** **US$ 1.74**
- **Dự báo tổng chi phí cả tháng (Projected Cost):** **US$ 1.75** (nằm an toàn trong ngân sách $100 của Learner Lab).

#### Phân rã chi phí theo dịch vụ:
1. **Amazon EC2 (Compute):** Chiếm **$1.20** (chi phí duy trì 3 instance EC2 `t3.medium` cho cụm Self-Managed trong các phiên thực nghiệm).
2. **Amazon EMR (Elastic MapReduce):** Chiếm **$0.25** (tối ưu chi phí nhờ chiến lược Transient Cluster – bật cụm, chạy xong Step tự Terminate).
3. **Amazon VPC & EC2-Other:** Chiếm **$0.20** (Địa chỉ IP và lưu trữ EBS gp3).
4. **Amazon S3:** Chiếm **$0.09** (Chi phí lưu trữ bộ dữ liệu 1GB/3GB/5GB và kết quả Output).


## CHƯƠNG 4: KHAI BÁO SỬ DỤNG TRÍ TUỆ NHÂN TẠO (AI DISCLAIMER)

Theo quy định môn học, nhóm khai báo việc sử dụng các công cụ AI hỗ trợ trong quá trình làm đồ án như sau:

| Công cụ AI / LLM | Nội dung AI hỗ trợ | Phần sinh viên tự kiểm tra & chỉnh sửa |
| :--- | :--- | :--- |
| **ChatGPT (GPT-4o)** | Gợi ý cấu trúc file CloudFormation `self-managed.yaml` và các câu lệnh AWS CLI EMR. | Tự điều chỉnh `SubnetId`, `InstanceProfile` phù hợp với tài nguyên Learner Lab; sửa lỗi tương thích phiên bản JAR `hadoop-aws`. |
| **Claude 3.5 Sonnet** | Hỗ trợ viết script PySpark WordCount & Aggregation mẫu; hỗ trợ phác thảo sơ đồ Mermaid. | Tự kiểm thử mã nguồn PySpark ở chế độ `local`, tinh chỉnh đường dẫn đọc/ghi trực tiếp từ S3 (`s3://hadoop-spark-lab-24139035/`). |
| **Amazon Q Developer** | Gợi ý câu lệnh shell script cài đặt Hadoop/Spark tự động. | Tự kiểm tra, gỡ lỗi phân quyền môi trường Linux và sửa lỗi đường dẫn biến môi trường `JAVA_HOME`, `HADOOP_HOME`. |

> **Cam kết:** Tất cả các tài nguyên đều được triển khai, thực thi và đo đạc thật 100% trên môi trường AWS Learner Lab. Thành viên nhóm hiểu rõ và sẵn sàng giải thích chi tiết mọi cấu hình, script khi vấn đáp.


## CHƯƠNG 5: KẾT LUẬN & HƯỚNG DẪN SỬ DỤNG

### 5.1. Kết luận & Đề xuất kiến trúc
- **Nên chọn Self-Managed (EC2) khi:** Cần tối ưu chi phí cố định cho các hệ thống chạy 24/7 ở quy mô vừa/nhỏ, cần can thiệp sâu vào cấu hình hệ thống tệp HDFS/YARN, hoặc phục vụ môi trường học tập/nghiên cứu Big Data.
- **Nên chọn Amazon EMR khi:** Triển khai môi trường Doanh nghiệp (Production), cần xử lý Big Data dung lượng lớn với tốc độ cao, hoặc chạy các tác vụ Batch Processing định kỳ tận dụng tính năng Transient Cluster tự xóa để tiết kiệm chi phí nhàn rỗi.

### 5.2. Hồ sơ minh chứng đính kèm
- **Repository Git:** [https://github.com/lhuynhu06-beep/DTDM](https://github.com/lhuynhu06-beep/DTDM)
- **Kịch bản CloudFormation:** `infra/self-managed.yaml`
- **Kịch bản khởi tạo EMR CLI:** `infra/emr-create.sh`
- **Bảng dữ liệu Benchmark gốc:** `benchmark/results.csv`
- **Hình ảnh minh chứng AWS Console:** Thư mục `docs/evidence/` (Tuần 1 đến Tuần 4)
- **Video Demo ($\le$ 10 phút):** Link đính kèm trong repository Git nhóm.
