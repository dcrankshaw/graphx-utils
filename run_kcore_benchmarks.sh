#!/usr/bin/env bash


TIME=/usr/bin/time
NODES=16
export SPARK=spark://$MASTERS:7077
export HDFS=hdfs://$MASTERS:9000

NUMTRIALS=1
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/debug_kcore_numbers
mkdir -p $OUTPUT_DIR

command=~/graphx/bin/run-example
class=org.apache.spark.graphx.lib.Analytics
# DATASET="livejournal_graph_splits/part*"
GX_DATASET="twitter_graph_splits/part*"
# DATASET="livejournal_graph"
NUMPARTS=64


GRAPHX_KCORE_COMMAND="$command $class $SPARK kcore \
  $HDFS/$GX_DATASET \
  --numEPart=$NUMPARTS \
  --kmax=4 --partStrategy=EdgePartition2D"

GRAPHX_KCORE_FILE=$OUTPUT_DIR/graphx_kcore_results_"$NUMPARTS"parts_$DATE
echo $GRAPHX_KCORE_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $GRAPHX_KCORE_FILE
echo $GRAPHX_KCORE_COMMAND | tee -a $GRAPHX_KCORE_FILE
~/graphx/sbin/stop-all.sh &> /dev/null
sleep 10
~/graphx/sbin/stop-all.sh &> /dev/null
~/graphx/sbin/start-all.sh &> /dev/null
sleep 10
for xx in $(seq 1 $NUMTRIALS)
do
  # hadoop dfs -rmr /kcore_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $GRAPHX_KCORE_COMMAND &>> $GRAPHX_KCORE_FILE
  # hadoop dfs -rmr /kcore_del
  echo Finished trial $xx
  sleep 10
  ~/graphx/sbin/stop-all.sh &> /dev/null
  sleep 10
  ~/graphx/sbin/stop-all.sh &> /dev/null
  ~/graphx/sbin/start-all.sh &> /dev/null
  sleep 10
  # sleep 60
done

echo -e "\n\n FINISHED GRAPHX\n\n"
exit

# ######################### GraphLab #######################################

GL_DATASET="twitter_graph_splits"
GL_KCORE_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES \
    env CLASSPATH=$(hadoop classpath) \
    $GRAPHLAB/release/toolkits/graph_analytics/kcore \
    --graph=$HDFS/$GL_DATASET --format=snap --ncpus=8 \
    --kmin=0 --kmax=4 --savecores=$HDFS/kcore_del"


GL_KCORE_FILE=$OUTPUT_DIR/graphlab_kcore_results_$DATE
echo $GL_KCORE_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_KCORE_FILE
echo $GL_KCORE_COMMAND | tee -a $GL_KCORE_FILE
for xx in $(seq 1 $NUMTRIALS)
do
  hadoop dfs -rmr /kcore_del* &> /dev/null
  $TIME -f "TOTAL_TIMEX: %e seconds" $GL_KCORE_COMMAND &>> $GL_KCORE_FILE
  # hadoop dfs -rmr /kcore_del* &> /dev/null
  echo Finished trial $xx
  sleep 30
done

echo -e "\n\n FINISHED GRAPHLAB\n\n"

