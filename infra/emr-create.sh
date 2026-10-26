#!/bin/bash
# Script tạo cụm AWS EMR + Submit Step WordCount + Auto Terminate

aws emr create-cluster \
    --name "EMR-Cluster-24139035" \
    --release-label emr-7.1.0 \
    --applications Name=Spark \
    --ec2-attributes KeyName=vockey,InstanceProfile=EMR_EC2_LabRole \
    --service-role EMR_DefaultRole \
    --instance-groups \
        InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.large \
        InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.large \
    --auto-terminate \
    --steps Type=Spark,Name="WordCount Step",ActionOnFailure=TERMINATE_CLUSTER,Args=[s3://hadoop-spark-lab-24139035-v2/scripts/wordcount.py] \
    --log-uri s3://hadoop-spark-lab-24139035-v2/logs/ \
    --tags Environment=Lab
