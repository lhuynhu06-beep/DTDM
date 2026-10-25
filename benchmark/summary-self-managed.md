# Kết quả benchmark – cụm tự dựng (1 master + 2 worker t3.medium)

Tổng số lần chạy: 24 (thành công 24). Thời gian = wall-clock của `spark-submit --deploy-mode cluster` (gồm cả xin container YARN), đọc/ghi trực tiếp S3 qua S3A.

Hai cụm GIỐNG HỆT NHAU (cùng 3 × t3.medium, cùng AMI, cùng cấu hình `conf/`) chạy song song để kịp phiên lab: cụm dựng bằng script (`script`) và cụm dựng bằng CloudFormation (`cloudformation`); mỗi cụm chỉ chạy 1 job tại một thời điểm.

| Cấu hình | Job | Dữ liệu (GB) | Cụm | Số lần | Trung bình (s) | Độ lệch chuẩn (s) | Min | Max | Thông lượng (MB/s) |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|
| baseline | aggregation | 1 | cloudformation | 3 | 118.4 | 6.6 | 113.3 | 127.7 | 8.6 |
| baseline | aggregation | 3 | cloudformation | 3 | 206.6 | 2.7 | 203.8 | 210.2 | 14.9 |
| baseline | aggregation | 5 | cloudformation | 3 | 285.7 | 7.7 | 275.2 | 293.4 | 17.9 |
| baseline | wordcount | 1 | script | 3 | 227.4 | 2.8 | 224.0 | 230.8 | 4.5 |
| baseline | wordcount | 3 | script | 3 | 577.4 | 4.0 | 574.5 | 583.1 | 5.3 |
| baseline | wordcount | 5 | cloudformation | 3 | 943.2 | 11.7 | 927.4 | 955.2 | 5.4 |
| tune-baseline | wordcount | 1 | script | 3 | 231.4 | 2.0 | 228.9 | 233.9 | 4.4 |
| tuned | wordcount | 1 | script | 3 | 210.0 | 0.8 | 209.0 | 211.0 | 4.9 |

## Trước / sau tối ưu Spark

| Cấu hình | Job | GB | Trước – tune-baseline (s) | Sau tối ưu (s) | Thay đổi |
|---|---|---:|---:|---:|---:|
| tuned | wordcount | 1 | 231.4 | 210.0 | -9.3% |

Ghi chú: 1 lần chạy WordCount 1 GB (413,4 s) bị loại vì chạy chồng với một job còn sót sau khi khởi động lại script benchmark – xem `results-excluded.csv`. Độ lệch chuẩn là độ lệch chuẩn tổng thể (n=3).
