#!/usr/bin/env bash

# Gives us $MASTERS env var
source ~/spark-ec2/ec2-variables.sh


TIME=/usr/bin/time


OUTPUT_DIR=/root/
source /root/spark-ec2/ec2-variables.sh
# mkdir -p $DF_OUTPUT_DIR

/root/rebuild-graphx
# Wikipedia
PR_COMMAND="/root/graphx/run-example \
org.apache.spark.graph.Analytics \
spark://$MASTERS:7077 \
pagerank hdfs://$MASTERS:9000/wiki_parsed3_edges \
--partStrategy=EdgePartition1D --tol=0.01 --numEPart=128"
PR_FILE=/root/graphx_pagerank_wikipedia
echo $PR_COMMAND | tee -a $PR_FILE
for xx in $(seq 1 10)
do
  $TIME -f "TOTAL: %e seconds" $PR_COMMAND 2>&1 | tee -a $PR_FILE
  sleep 60
done
