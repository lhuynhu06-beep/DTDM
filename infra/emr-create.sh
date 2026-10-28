aws emr create-cluster \
    --name "EMR-Spark-Cluster-24139035" \
    --release-label emr-5.36.0 \
    --applications Name=Hadoop Name=Spark \
    --service-role EMR_DefaultRole \
    --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,KeyName=vockey \
    --instance-groups \
        InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.large \
        InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.large \
    --auto-terminate \
    --steps Type=Spark,Name="WordCount Step",ActionOnFailure=TERMINATE_CLUSTER,Args=[s3://hadoop-spark-lab-24139035/jobs/wordcount.py,s3://hadoop-spark-lab-24139035/data/ChiPheo.txt,s3://hadoop-spark-lab-24139035/output/] \
    --log-uri s3://hadoop-spark-lab-24139035/logs/ \
    --region us-east-1 \
    --tags "Project=Hadoop-EMR-Compare" "Owner=24139035"
