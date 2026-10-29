**Tuần 2 (26/10–01/11/2026)**: phần của Đỗ Minh Hiển (24139013)
*(Ghi chú trung thực: toàn bộ phần kỹ thuật được làm sớm vào ngày 25/10/2026 trên Learner Lab, Account 2111-2549-0692, us-east-1.)*

**Đỗ Minh Hiển (24139013)**
- **Cấu hình HDFS/YARN:**
  - Các file `conf/hadoop/{core,hdfs,yarn,mapred}-site.xml` và `workers` được đưa lên node bằng `scripts/install-hadoop.sh`.
  - `fs.defaultFS=hdfs://hadoop-master:9000`, `dfs.replication=2`, thư mục dữ liệu nằm ở `/data/hadoop`.
  - YARN cho mỗi worker 3072 MB và 2 vcores. Giới hạn container 512–3072 MB, tắt vmem-check.
  - Format NameNode chỉ chạy lần đầu.
- **Spark trên YARN** (`scripts/install-spark.sh`, `conf/spark/spark-defaults.conf`):
  - Spark 3.5.5 bản without-hadoop. Executor 1g, 1 core, 3 instance; driver 1g.
  - `spark.yarn.archive` trỏ tới `hdfs:///spark/spark-libs.zip`. Event log và History Server bật ở cổng 18080.
- **S3A:**
  - Dùng `hadoop-aws-3.3.6` + `aws-java-sdk-bundle-1.12.367` có sẵn trong `tools/lib`, nên khớp đúng phiên bản Hadoop 3.3.6.
  - Credentials lấy qua `IAMInstanceCredentialsProvider`, tức LabInstanceProfile với IMDSv2.
  - Đã kiểm tra `hadoop fs -ls s3a://…/jobs/` chạy được.
- **Bucket riêng** `hadoop-spark-24139013-211125490692` (`infra/s3-bucket.sh`):
  - Bật Block Public Access, SSE-S3, tag Project/Owner.
  - Có các thư mục `data/ jobs/ logs/ results/ artifacts/`.
  - Lý do dùng bucket riêng: bucket nhóm `hadoop-spark-lab-24139035` trả về NoSuchBucket.
- **Dữ liệu benchmark** (`jobs/gen_data.py`, `benchmark/gen-data.sh`):
  - Sinh bằng chính cụm Spark: text tiếng Việt tổng hợp theo phân bố Zipf và CSV giao dịch bán hàng.
  - Mỗi loại có 3 mức 1/3/5 GB (8/24/40 file × 128 MB), lưu ở `s3://…/data/{text,csv}/{1g,3g,5g}/`.
- **Script tự động:** `install-hadoop.sh`, `install-spark.sh`, `start-cluster.sh`, `stop-cluster.sh`, `configure-cluster.sh`. Lệnh `configure-cluster.sh` cấu hình và khởi động cả cụm trong 1 phút 08 giây.
- **Kết quả kiểm tra:**
  - `hdfs dfsadmin -report`: Live datanodes (2), 59,85 GB.
  - `yarn node -list`: 2 node RUNNING.
  - `jps` đúng vai trò từng node.
  - WordCount và aggregation chạy từ S3 và ghi kết quả vào `results/self-managed/`.
- **Minh chứng:** `docs/evidence/w2/` (ảnh dfsadmin/yarn/jps), log spark-submit trong `benchmark/logs/`.
- **Khó khăn:**
  - (1) `jps` không có trong gói JDK headless; đã đổi sang gói `java-11-amazon-corretto-devel`.
  - (2) Bản đầu của trình sinh dữ liệu quá chậm (khoảng 2 MB/s mỗi core). Đã đổi sang cách bốc theo dòng từ kho câu Zipf, nhanh hơn khoảng 20 lần.

**Góp ý giao thức benchmark (gửi Như):**
- Đo bằng wall-clock của `spark-submit --deploy-mode cluster`, giống cách tính 1 Step trên EMR.
- Mỗi mức dữ liệu chạy 3 lần lấy trung bình; ghi thêm độ lệch chuẩn.
- Ghi chú thêm: t3.medium là CPU burstable, nên theo dõi `CPUCreditBalance`; m4.large có 8 GiB RAM nên mặc định được cấp executor lớn hơn.

**Phần có AI hỗ trợ:** Claude (Anthropic), claude-opus-5-5.
- Prompt: "làm tiếp Tuần 2–4 nhánh tự dựng".
- AI tạo: các file cấu hình XML, các script cài đặt và khởi động, trình sinh dữ liệu.
- Tự kiểm tra: Đã đọc lại toàn bộ nội dung cấu hình, chạy thử nghiệm thực tế trên môi trường AWS Learner Lab, kiểm tra tính tương thích của các tham số YARN/Spark với giới hạn bộ nhớ của instance `t3.medium` và xác thực kết quả chạy lệnh thành công.
