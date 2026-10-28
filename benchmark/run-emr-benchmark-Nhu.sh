#!/bin/bash
# Description: Tự động hóa khởi tạo cụm EMR (3 node m4.large, phiên bản 5.36.0),
#              nạp tuần tự các Step benchmark (WordCount + Aggregation) cho 
#              các mức dữ liệu 1GB, 3GB, 5GB và tự động hủy cụm sau khi hoàn thành.
# Chạy từng khối lệnh độc lập trong CloudShell để tránh vượt hạn mức tài nguyên Lab.

# [KHỐI 1] BENCHMARK MỨC DỮ LIỆU 1 GiB (WordCount & Aggregation)

aws emr create-cluster \
    --name "EMR-Benchmark-1GB-24139035" \
    --release-label emr-5.36.0 \
    --applications Name=Hadoop Name=Spark \
    --service-role EMR_DefaultRole \
    --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,KeyName=vockey \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.large InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.large \
    --auto-terminate \
    --steps \
        Type=Spark,Name="WordCount-1GB-Run1",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_1gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_1gb_r1/] \
        Type=Spark,Name="WordCount-1GB-Run2",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_1gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_1gb_r2/] \
        Type=Spark,Name="WordCount-1GB-Run3",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_1gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_1gb_r3/] \
        Type=Spark,Name="Agg-1GB-Run1",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_1gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_1gb_r1/] \
        Type=Spark,Name="Agg-1GB-Run2",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_1gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_1gb_r2/] \
        Type=Spark,Name="Agg-1GB-Run3",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_1gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_1gb_r3/] \
    --region us-east-1


# [KHỐI 2] BENCHMARK MỨC DỮ LIỆU 3 GiB (WordCount & Aggregation)
# Chỉ chạy khi cụm 1GB ở trên đã hoàn thành nhiệm vụ và tắt hoàn toàn.

aws emr create-cluster \
    --name "EMR-Benchmark-3GB-24139035" \
    --release-label emr-5.36.0 \
    --applications Name=Hadoop Name=Spark \
    --service-role EMR_DefaultRole \
    --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,KeyName=vockey \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.large InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.large \
    --auto-terminate \
    --steps \
        Type=Spark,Name="WordCount-3GB-Run1",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_3gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_3gb_r1/] \
        Type=Spark,Name="WordCount-3GB-Run2",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_3gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_3gb_r2/] \
        Type=Spark,Name="WordCount-3GB-Run3",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_3gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_3gb_r3/] \
        Type=Spark,Name="Agg-3GB-Run1",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_3gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_3gb_r1/] \
        Type=Spark,Name="Agg-3GB-Run2",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_3gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_3gb_r2/] \
        Type=Spark,Name="Agg-3GB-Run3",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_3gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_3gb_r3/] \
    --region us-east-1

# [KHỐI 3] BENCHMARK MỨC DỮ LIỆU 5 GiB (WordCount & Aggregation)
# Khối lệnh Stress Test cuối cùng, chạy sau khi cụm 3GB đã tắt.

aws emr create-cluster \
    --name "EMR-Benchmark-5GB-24139035" \
    --release-label emr-5.36.0 \
    --applications Name=Hadoop Name=Spark \
    --service-role EMR_DefaultRole \
    --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,KeyName=vockey \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.large InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.large \
    --auto-terminate \
    --steps \
        Type=Spark,Name="WordCount-5GB-Run1",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_5gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_5gb_r1/] \
        Type=Spark,Name="WordCount-5GB-Run2",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_5gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_5gb_r2/] \
        Type=Spark,Name="WordCount-5GB-Run3",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/data_5gb.txt,s3://hadoop-spark-lab-24139035/results/emr/wc_5gb_r3/] \
        Type=Spark,Name="Agg-5GB-Run1",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_5gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_5gb_r1/] \
        Type=Spark,Name="Agg-5GB-Run2",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_5gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_5gb_r2/] \
        Type=Spark,Name="Agg-5GB-Run3",ActionOnFailure=CONTINUE,Args=[s3://hadoop-spark-lab-24139035/jobs/aggregation.py,s3://hadoop-spark-lab-24139035/data/data_5gb.txt,s3://hadoop-spark-lab-24139035/results/emr/agg_5gb_r3/] \
    --region us-east-1
