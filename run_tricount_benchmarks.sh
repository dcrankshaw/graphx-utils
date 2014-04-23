#!/usr/bin/env bash


TIME=/usr/bin/time
NODES=16
export SPARK=spark://$MASTERS:7077
export HDFS=hdfs://$MASTERS:9000

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/debug_tc_numbers
mkdir -p $OUTPUT_DIR

command=~/graphx/bin/run-example
class=org.apache.spark.graphx.lib.Analytics
# DATASET="livejournal_graph_splits/part*"
GX_DATASET="twitter_graph_splits/part*"
# DATASET="livejournal_graph"
NUMPARTS=64


GRAPHX_TC_COMMAND="$command $class $SPARK triangles \
  $HDFS/$GX_DATASET \
  --numEPart=$NUMPARTS \
  --partStrategy=EdgePartition2D"

GRAPHX_TC_FILE=$OUTPUT_DIR/graphx_tc_results_"$NUMPARTS"parts_$DATE
echo $GRAPHX_TC_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $GRAPHX_TC_FILE
echo $GRAPHX_TC_COMMAND | tee -a $GRAPHX_TC_FILE
~/graphx/sbin/stop-all.sh &> /dev/null
sleep 10
~/graphx/sbin/stop-all.sh &> /dev/null
~/graphx/sbin/start-all.sh &> /dev/null
sleep 10
for xx in $(seq 1 $NUMTRIALS)
do
  # hadoop dfs -rmr /tc_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $GRAPHX_TC_COMMAND &>> $GRAPHX_TC_FILE
  # hadoop dfs -rmr /tc_del
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

# ######################### GraphLab #######################################

GL_DATASET="twitter_graph_splits"
GL_TC_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES \
    env CLASSPATH=$(hadoop classpath) \
    $GRAPHLAB/release/toolkits/graph_analytics/undirected_triangle_count \
    --graph=$HDFS/$GL_DATASET --format=snap --ncpus=8"
    # --saveprefix=$HDFS/tc_del"

GL_TC_FILE=$OUTPUT_DIR/graphlab_tc_results_$DATE
echo $GL_TC_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_TC_FILE
echo $GL_TC_COMMAND | tee -a $GL_TC_FILE
for xx in $(seq 1 $NUMTRIALS)
do
  hadoop dfs -rmr /tc_del* &> /dev/null
  $TIME -f "TOTAL_TIMEX: %e seconds" $GL_TC_COMMAND &>> $GL_TC_FILE
  hadoop dfs -rmr /tc_del* &> /dev/null
  echo Finished trial $xx
  sleep 30
done

echo -e "\n\n FINISHED GRAPHLAB\n\n"

