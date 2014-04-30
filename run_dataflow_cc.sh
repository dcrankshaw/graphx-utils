#!/usr/bin/env bash


TIME=/usr/bin/time
export SPARK=spark://$MASTERS:7077
export HDFS=hdfs://$MASTERS:9000

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/debug_cc
mkdir -p $OUTPUT_DIR
CC_ITERS=20

command=/mnt/graphx/bin/run-example
class=org.apache.spark.graphx.lib.DataflowPagerank
GX_DATASET="twitter_graph_splits/part*"
# GX_DATASET="lj_graph_splits/part*"
NUMPARTS=128


CC_COMMAND="$command $class $SPARK \
  $HDFS/$GX_DATASET \
  $CC_ITERS $NUMPARTS cc"

CC_FILE=$OUTPUT_DIR/naivespark_cc_results_"$NUMPARTS"parts_$DATE
echo $CC_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $CC_FILE
cd /mnt/graphx
# GRAPHX_SHA=`git rev-parse HEAD`
GRAPHX_SHA=`git log -1 --decorate`
cd -
echo $GRAPHX_SHA >> $CC_FILE
echo $CC_COMMAND | tee -a $CC_FILE
/mnt/graphx/sbin/stop-all.sh &> /dev/null
sleep 10
/mnt/graphx/sbin/stop-all.sh &> /dev/null
/mnt/graphx/sbin/start-all.sh &> /dev/null
sleep 10
for xx in $(seq 1 $NUMTRIALS)
do
  # hadoop dfs -rmr /pr_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $CC_COMMAND &>> $CC_FILE
  # hadoop dfs -rmr /pr_del
  echo Finished trial $xx
  sleep 10
  /mnt/graphx/sbin/stop-all.sh &> /dev/null
  sleep 10
  /mnt/graphx/sbin/stop-all.sh &> /dev/null
  /mnt/graphx/sbin/start-all.sh &> /dev/null
  sleep 10
  # sleep 60
done

echo -e "\n\n FINISHED NAIVE SPARK CONNECTED COMPONENTS\n\n"

