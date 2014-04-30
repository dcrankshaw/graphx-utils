#!/usr/bin/env bash


TIME=/usr/bin/time

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/debug_cc
mkdir -p $OUTPUT_DIR

command=/mnt/graphx/bin/run-example
class=org.apache.spark.graphx.lib.Analytics
# DATASET="livejournal_graph_splits/part*"
DATASET="twitter_graph_splits/part*"
# DATASET="livejournal_graph"
NUMPARTS=128

export HDFS=hdfs://$MASTERS:9000

###################### GraphX #################################
# GRAPHX_CC_COMMAND="$command $class spark://$MASTERS:7077 cc \
#   $HDFS/$DATASET \
#   --numEPart=$NUMPARTS \
#   --dynamic=true"
#
# GRAPHX_CC_FILE=$OUTPUT_DIR/graphx_cc_results_"$NUMPARTS"parts_$DATE
# echo $GRAPHX_CC_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $GRAPHX_CC_FILE
# cd /mnt/graphx
# # GRAPHX_SHA=`git rev-parse HEAD`
# GRAPHX_SHA=`git log -1 --decorate`
# cd -
# echo $GRAPHX_SHA >> $GRAPHX_CC_FILE
# echo $GRAPHX_CC_COMMAND | tee -a $GRAPHX_CC_FILE
# /mnt/graphx/sbin/stop-all.sh &> /dev/null
# sleep 10
# /mnt/graphx/sbin/stop-all.sh &> /dev/null
# /mnt/graphx/sbin/start-all.sh &> /dev/null
# sleep 10
# for xx in $(seq 1 $NUMTRIALS)
# do
#   # hadoop dfs -rmr /cc_del
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GRAPHX_CC_COMMAND &>> $GRAPHX_CC_FILE
#   # hadoop dfs -rmr /cc_del
#   echo Finished iter $xx
#   sleep 10
#   /mnt/graphx/sbin/stop-all.sh &> /dev/null
#   sleep 10
#   /mnt/graphx/sbin/stop-all.sh &> /dev/null
#   /mnt/graphx/sbin/start-all.sh &> /dev/null
#   sleep 10
#   # sleep 60
# done
#
# echo -e "\n\n FINISHED GRAPHX\n\n" | tee ~/GRAPHX_DONE

# ######################### GraphLab #######################################

GL_DATASET="twitter_graph_splits"
# GL_CC_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES env \
#     CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/connected_component \
#     --graph=$HDFS/$GL_DATASET --format=snap --ncpus=8 \
#     --saveprefix=$HDFS/cc_del"

NODES=128
CPUS=1
GL_CC_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES env \
    CLASSPATH=$(hadoop classpath) \
    $GRAPHLAB/release/toolkits/graph_analytics/connected_component \
    --graph=$HDFS/$GL_DATASET --format=snap --ncpus=$CPUS \
    --graph_opts=ingress=random"
    # --saveprefix=$HDFS/cc_del"

GL_CC_FILE=$OUTPUT_DIR/graphlab_cc_nodes$NODES-cpus$CPUS-$DATE
echo $GL_CC_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_CC_FILE
echo $GL_CC_COMMAND | tee -a $GL_CC_FILE
for xx in $(seq 1 $NUMTRIALS)
do
  hadoop dfs -rmr /cc_del* &> /dev/null
  $TIME -f "TOTAL_TIMEX: %e seconds" $GL_CC_COMMAND &>> $GL_CC_FILE
  hadoop dfs -rmr /cc_del* &> /dev/null
  echo Finished iter $xx
  sleep 30
done

echo -e "\n\n FINISHED GRAPHLAB\n\n" | tee ~/GRAPHLAB_DONE

