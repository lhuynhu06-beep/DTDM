# Các chương của nhánh tự dựng (Self-managed): Đỗ Minh Hiển (24139013)

> Bản nháp để ghép vào báo cáo chung do trưởng nhóm tổng hợp. Số liệu benchmark lấy từ
> `benchmark/results-self-managed.csv`. Ảnh minh chứng nằm trong `docs/evidence/`.

---

## Chương A. Kiến trúc Hadoop 3 và Spark-on-YARN

### A.1 HDFS
HDFS là hệ thống tệp phân tán theo mô hình master/worker:

- **NameNode** quản lý *namespace*, tức cây thư mục và quyền. Nó cũng giữ ánh xạ *file → danh sách block → DataNode chứa block*. Toàn bộ metadata nằm trong RAM; bản bền vững được ghi xuống đĩa thành `fsimage` cộng nhật ký `edits`. Khi đọc, client hỏi NameNode vị trí các block, rồi đọc thẳng từ DataNode. Nhờ vậy NameNode không trở thành nút cổ chai về băng thông.
- **DataNode** lưu block (mặc định 128 MB) trên đĩa cục bộ. Cứ 3 giây nó gửi một *heartbeat* và định kỳ gửi *block report*. Nếu một DataNode mất heartbeat quá khoảng 10 phút, NameNode coi node đó đã chết và cho nhân bản lại các block thiếu.
- **SecondaryNameNode** định kỳ gộp `fsimage` với `edits` để tạo checkpoint, giúp NameNode khởi động lại nhanh. Đây **không** phải node dự phòng nóng (HA).
- **Hệ số nhân bản:** cụm có 2 DataNode nên chọn `dfs.replication = 2`. Giữ mặc định 3 thì mọi block sẽ luôn ở trạng thái under-replicated.

### A.2 YARN
- **ResourceManager (RM)** gồm *Scheduler* (cấp container theo RAM và vCPU, ở đây dùng CapacityScheduler mặc định) và *ApplicationsManager* (nhận ứng dụng, khởi động ApplicationMaster).
- **NodeManager (NM)** chạy trên mỗi worker. Nó báo tài nguyên về RM, rồi khởi chạy và giám sát container.
- **ApplicationMaster (AM)**: mỗi ứng dụng có một AM, chạy trong container riêng. AM xin thêm container từ RM để chạy các task.

### A.3 Spark-on-YARN
`spark-submit --master yarn` đăng ký ứng dụng với RM. Mỗi **executor** của Spark là một container YARN.

- **client mode:** driver chạy ngay trên máy submit.
- **cluster mode:** driver chạy trong container AM trên một worker. Nhóm dùng **cluster mode** khi benchmark để giống cách EMR chạy một Step.
- Dữ liệu vào/ra đi qua connector **S3A** (`s3a://`). Thông tin xác thực là credentials tạm thời lấy từ *instance profile* qua IMDSv2 (`IAMInstanceCredentialsProvider`), nên không có access key nào nằm trên máy.

---

## Chương B. Triển khai cụm tự dựng trên EC2

### B.1 Thiết kế
| Node | Loại | Tiến trình |
|---|---|---|
| hadoop-master | t3.medium (2 vCPU, 4 GiB) | NameNode, SecondaryNameNode, ResourceManager, JobHistory, Spark History |
| hadoop-worker1/2 | t3.medium | DataNode, NodeManager, Spark executor |

- Mỗi node có ổ gp3 30 GB và gắn `LabInstanceProfile`.
- Cả 3 node ở cùng subnet us-east-1a.
- `/etc/hosts` dùng **private IP**, vì private IP giữ nguyên khi Stop/Start, còn public IP thì đổi.
- Master không chạy DataNode/NodeManager. Như vậy topology "1 điều phối + 2 xử lý" giống EMR (primary + 2 core).

Sơ đồ: `docs/diagrams/self-managed-architecture.png`.

### B.2 Phần mềm và lý do chọn phiên bản
- Amazon Linux 2023, Amazon Corretto 11 (bản build OpenJDK 11), Hadoop 3.3.6, Spark 3.5.5.
- Dùng bản Spark **bin-without-hadoop**: Spark chạy trên đúng thư viện Hadoop 3.3.6 đã cài (`SPARK_DIST_CLASSPATH`). Jar S3A (`hadoop-aws-3.3.6` + `aws-java-sdk-bundle-1.12.367`) có sẵn trong `share/hadoop/tools/lib` của Hadoop, nên phiên bản tự khớp. Nếu ghép `hadoop-aws` 3.3.6 với `hadoop-client` 3.3.4 đóng gói trong bản `spark-bin-hadoop3`, dễ gặp `NoSuchMethodError`.
- Jar của Spark được nén một lần vào `hdfs:///spark/spark-libs.zip` (`spark.yarn.archive`), nên mỗi lần submit không phải upload lại khoảng 200 MB.

### B.3 Cấu hình bộ nhớ cho máy 4 GiB
| Tham số | Giá trị | Giải thích |
|---|---|---|
| `yarn.nodemanager.resource.memory-mb` | 3072 | khoảng 1 GiB để lại cho OS, DataNode, NodeManager |
| `yarn.nodemanager.resource.cpu-vcores` | 2 | bằng số vCPU |
| `yarn.scheduler.minimum/maximum-allocation-mb` | 512 / 3072 | container được làm tròn lên bội số 512 |
| `yarn.nodemanager.vmem-check-enabled` | false | tránh container JVM bị kill oan do virtual memory |
| `spark.executor.memory` / `cores` / `instances` | 1g / 1 / 3 | 1g + 384m overhead, làm tròn thành container 1536 MB |
| `spark.driver.memory` | 1g | driver/AM cũng chiếm một container 1536 MB |

Tổng: 4 container × 1536 MB = 6144 MB, đúng bằng 2 × 3072 MB. Cụm dùng hết RAM container mà không có container nào phải chờ.

### B.4 Quy trình dựng bằng script (Tuần 1–2)
```bash
./infra/ec2-cluster.sh up            # SG + 3 EC2 (tag, LabInstanceProfile, gp3)    ~40 giây
./scripts/bootstrap-cluster.sh       # Java, Hadoop, Spark, /etc/hosts, SSH          1 phút 44 giây
./infra/s3-bucket.sh                 # bucket riêng: Block Public Access, SSE-S3, tag
./scripts/configure-cluster.sh       # *-site.xml, format NameNode, start HDFS/YARN  ~1 phút 08 giây
```

Kết quả kiểm tra:
- `hdfs dfsadmin -report`: *Live datanodes (2)*, dung lượng 59,85 GB.
- `yarn node -list`: 2 node ở trạng thái RUNNING.
- `jps` trên master: NameNode, SecondaryNameNode, ResourceManager, JobHistoryServer, HistoryServer.
- `jps` trên mỗi worker: DataNode, NodeManager.

### B.5 Sự cố gặp phải và cách xử lý
| Sự cố | Nguyên nhân | Cách xử lý |
|---|---|---|
| `UnauthorizedOperation` khi gọi `ec2:DescribeVpcs` | Terminal trong trang Learner Lab chạy bằng role `runserver` của Vocareum | Chạy mọi lệnh trong **AWS CloudShell** (dùng quyền voclabs của phiên lab) |
| `jps: command not found` | gói `java-11-amazon-corretto-headless` không có công cụ JDK | Cài `java-11-amazon-corretto-devel` |
| Bucket nhóm `hadoop-spark-lab-24139035` báo `NoSuchBucket` | bucket chưa được tạo hoặc sai tên, và nằm ở tài khoản khác | Tạo bucket riêng `hadoop-spark-24139013-<account>` |
| Sinh dữ liệu chỉ đạt ~2 MB/s mỗi core | bốc từng từ theo Zipf bằng Python quá chậm | Dựng một kho câu theo Zipf rồi bốc theo dòng; nhanh hơn khoảng 20 lần mà vẫn giữ phân bố |
| Lần dựng CFN đầu không hoàn tất | `dnf` trên worker2 báo "Unable to find a match" lúc máy vừa boot | Thử lại 5 lần, `dnf clean metadata` giữa các lần |
| Log của `spark-submit` trống, script benchmark ghi nhầm exit_code=2 | client spark-submit không in log trên cụm này (nghi do xung đột binding SLF4J giữa Hadoop và Spark) | Lấy trạng thái cuối trực tiếp từ YARN (`yarn application -list -appStates ALL`); thêm `fix-status.sh` để sửa các dòng cũ |
| Mất kết nối SSH sau khi CloudShell hết phiên | IP public của CloudShell đổi | Thêm IP mới vào SG của cụm script; với cụm CFN thì cập nhật stack (tham số `SshCidr`) |

---

## Chương C. Hạ tầng dạng mã (IaC) với CloudFormation

Template `infra/self-managed.yaml` dựng toàn bộ cụm bằng một lệnh:

```bash
aws cloudformation deploy --template-file infra/self-managed.yaml --stack-name hadoop-cfn \
  --parameter-overrides ArtifactBucket=$BUCKET SshCidr=<IP>/32 "OperatorPublicKey=$(cat ~/.ssh/id_ed25519.pub)" \
  --tags Project=HadoopSpark-EC2-vs-EMR Owner=24139013
```

- **Mạng:** VPC riêng `10.30.0.0/16`, public subnet `10.30.1.0/24` ở us-east-1a, Internet Gateway, route table. Có thêm **S3 Gateway Endpoint** (miễn phí) để lưu lượng S3A không đi qua Internet.
- **Security Group:** chỉ mở 22/tcp từ `SshCidr`. Mọi cổng nội bộ chỉ cho phép từ chính SG (rule tự tham chiếu).
- **3 EC2 với private IP cố định** (`.10/.11/.12`): `/etc/hosts` biết trước nên không cần dò IP. Mỗi node gắn `LabInstanceProfile`, bắt buộc IMDSv2, gắn đủ tag.
- **User-data:** tải gói mã nguồn từ S3, rồi chạy lần lượt `setup-base.sh`, `install-hadoop.sh`, `install-spark.sh` và CloudWatch Agent.
  - Để có SSH không mật khẩu, master công bố public key lên `s3://…/artifacts/<StackId>/master.pub`; worker tự tải về.
  - Master chờ SSH được tới cả 2 worker, chạy `start-cluster.sh`, kiểm tra **Live datanodes = 2** rồi mới gửi `cfn-signal`.
  - `CreationPolicy` (30 phút) bảo đảm stack chỉ **CREATE_COMPLETE** khi cụm đã thật sự chạy được.
- **Output:** IP master, lệnh SSH và lệnh SSH tunnel để xem các giao diện web.

---

## Chương D. Bảo mật và giám sát cụm EC2

### D.1 Bảo mật
- **Mạng:** không cổng web nào (9870, 8088, 18080, 19888) mở ra Internet. Xem giao diện qua SSH tunnel:
  `ssh -N -L 9870:hadoop-master:9870 -L 8088:hadoop-master:8088 -L 18080:hadoop-master:18080 ec2-user@<master>`
- **Danh tính:** chỉ dùng `LabInstanceProfile`/`LabRole` có sẵn, không tạo IAM user hay role mới. Không có access key nào nằm trên máy hoặc trong mã nguồn. IMDSv2 bắt buộc (`HttpTokens=required`).
- **Dữ liệu:** bucket bật Block Public Access cả 4 mục và mã hoá mặc định SSE-S3 (AES-256, Bucket Key).
- **SSH:** giữa các node dùng khoá ed25519 riêng của cụm. Khoá của máy điều khiển chỉ được thêm qua user-data dưới dạng public key.

### D.2 Giám sát
- **CloudWatch Agent** (`monitoring/cloudwatch-agent.json`) chạy trên cả 3 node. Nó đẩy `mem_used_percent`, `disk_used_percent` (thư mục `/`), `cpu usage_active/iowait` và swap vào namespace `HadoopSelfManaged` mỗi 60 giây.
- **Dashboard `HadoopSelfManaged-hadoop-selfmanaged`** có các biểu đồ: CPU (AWS/EC2), RAM, Disk, **CPUCreditBalance** (quan trọng vì t3 là loại CPU burstable) và Network-in.
- **Alarm:**
  - `hadoop-selfmanaged-worker1-mem-high`: RAM của worker1 trên 90% trong 3 phút.
  - `hadoop-selfmanaged-master-cpu-high`: CPU của master trên 85% trong 5 phút.

---

## Chương E. Kết quả benchmark cụm tự dựng

**Giao thức đo:**
- Mỗi lần đo là thời gian wall-clock của `spark-submit --deploy-mode cluster`, đọc và ghi thẳng trên S3 qua S3A.
- 3 mức dữ liệu (1, 3, 5 GB) × 3 lần × 2 job; dữ liệu sinh bằng `jobs/gen_data.py`, seed cố định.
- Job: `wordcount.py` (PySpark RDD) trên text và `aggregation.py` (DataFrame, group by cột đầu, `inferSchema`) trên CSV.

Hai cụm **giống hệt nhau** (3 × t3.medium, cùng AMI, cùng `conf/`) chạy song song để kịp phiên lab: cụm dựng bằng script và cụm dựng bằng CloudFormation. Mỗi cụm chỉ chạy một job tại một thời điểm. Dữ liệu thô nằm trong `benchmark/results-self-managed.csv`.

| Job | 1 GB | 3 GB | 5 GB | Thông lượng ở 5 GB |
|---|---:|---:|---:|---:|
| WordCount (s, TB ± ĐLC, n=3) | 227,4 ± 2,8 | 577,4 ± 4,0 | 943,2 ± 11,7 | 5,4 MB/s |
| Aggregation (s, TB ± ĐLC, n=3) | 118,4 ± 6,6 | 206,6 ± 2,7 | 285,7 ± 7,7 | 17,9 MB/s |

![Thời gian chạy](../benchmark/runtime-self-managed.png)

**Nhận xét:**
1. **WordCount gần như tuyến tính** theo kích thước: 1 → 5 GB tăng 4,1 lần, thông lượng giữ ổn định khoảng 5 MB/s. Job bị giới hạn bởi CPU: mỗi dòng phải đi qua Python worker (lambda `split`/`map` của RDD), nên chi phí trên mỗi byte gần như cố định.
2. **Aggregation tăng chậm hơn**: 1 → 5 GB chỉ tăng 2,4 lần, thông lượng tăng từ 8,6 lên 17,9 MB/s. Job dùng DataFrame (Catalyst/Tungsten, không qua Python) nên tính toán rất nhẹ. Ở mức 1 GB, phần chi phí cố định (khởi động AM và executor, khoảng 20–30 s) cùng lượt đọc thêm của `inferSchema` chiếm tỉ trọng lớn.
3. **Độ ổn định cao**: hệ số biến thiên dưới 6% ở mọi mức.
4. **CPU credit:** dashboard cho thấy `CPUCreditBalance` của 2 worker về 0 ngay sau vài phút đầu và giữ ở 0 suốt benchmark, trong khi CPU worker ở mức 60–95%. Instance chạy ở chế độ *unlimited* nên không bị bóp xuống mức baseline 20%, nhưng phát sinh phí credit vượt. Khi so với m4.large (CPU cố định, 8 GiB) cần tính đến điểm này.

### E.1 Tối ưu Spark (trước/sau, trên cùng một cụm, WordCount 1 GB, n=3)
| Cấu hình | Executor | Thời gian (s) |
|---|---|---:|
| Trước: mặc định của cụm | 3 × (1 core, 1g), driver 1g; 8 task / 3 core | 231,4 ± 2,0 |
| Sau | 2 × (2 core, 1600m), driver 512m; `maxPartitionBytes=64m` → 16 task / 4 core | **210,0 ± 0,8** (**−9,3%**) |

**Giải thích:**
- Hạ bộ nhớ driver/AM xuống 512m giải phóng đủ RAM để chạy 4 core thay vì 3 trong cùng 6144 MB container.
- Chia nhỏ partition giúp các core được chia việc đều hơn.
- Mức cải thiện nhỏ hơn mức tăng số core (+33%). Lý do: t3.medium chỉ có 2 vCPU mỗi worker, mà Python worker cùng JVM tranh nhau CPU trên đúng 2 vCPU đó, cộng thêm chi phí cố định khi khởi động.
- Hướng cải thiện lớn hơn nằm ở mã nguồn: viết lại WordCount bằng DataFrame (`split` + `explode` + `groupBy`) để tránh lambda Python. Việc này nằm ngoài phạm vi "cùng một job" của giao thức benchmark.

### E.2 Công sức và thời gian dựng cụm
| Cách dựng | Số lệnh | Thời gian đến khi cụm chạy được |
|---|---|---|
| Script | 4 (`ec2-cluster.sh up`, `bootstrap-cluster.sh`, `s3-bucket.sh`, `configure-cluster.sh`) | khoảng 40 giây + 1 phút 44 giây + 1 phút 08 giây ≈ **3,5 phút** máy chạy, chưa tính thời gian gõ lệnh |
| CloudFormation | 1 (`aws cloudformation deploy`) | **4 phút 37 giây**, gồm cả VPC và kiểm tra 2 DataNode |

### E.3 Chi phí ước tính của nhánh tự dựng (giá On-Demand us-east-1, tham khảo 10/2026)
| Hạng mục | Đơn giá | Dùng thực tế 25/10 | Ước tính |
|---|---|---|---:|
| EC2 t3.medium | $0,0416/giờ | khoảng 1,8 giờ (cụm script) + 1,6 giờ (2 lần dựng CFN), × 3 node | khoảng $0,42 |
| Credit vượt (t3 unlimited) | $0,05/vCPU-giờ | khoảng 6 vCPU-giờ | khoảng $0,30 |
| EBS gp3 | $0,08/GB-tháng | 6 × 30 GB, **vẫn tính phí khi máy đã Stop** | khoảng $0,48/ngày nếu giữ |
| S3 Standard | khoảng $0,023/GB-tháng | khoảng 18 GB dữ liệu | khoảng $0,41/tháng |

Bảng so sánh với EMR (m4.large cộng phí EMR) do Như tổng hợp.
