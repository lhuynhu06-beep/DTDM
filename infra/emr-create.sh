#!/bin/bash
# Script tạo cụm AWS EMR + Submit Step WordCount + Auto Terminate

aws emr create-cluster \
    --name "EMR-Spark-Cluster-Nhu" \
    --release-label emr-6.10.0 \
    --applications Name=Spark Name=Zeppelin \
    --ec2-attributes KeyName=vockey,InstanceProfile=EMR_EC2_DefaultRole \
    --service-role EMR_DefaultRole \
    --instance-groups \
        InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.xlarge \
        InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.xlarge \
    --auto-terminate \
    --steps Type=Spark,Name="WordCount Step",ActionOnFailure=TERMINATE_CLUSTER,Args=[s3://hadoop-spark-lab-24139035/scripts/wordcount.py] \
    --log-uri s3://hadoop-spark-lab-24139035/logs/ \
    --tags "Environment=Lab"
