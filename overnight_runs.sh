#!/usr/bin/env bash

TIME=/usr/bin/time
export SPARK=spark://$MASTERS:7077
export HDFS=hdfs://$MASTERS:9000

######################################
# GRAPHLAB KCORE TWITTER

# NUMTRIALS=3
# NOW=$(date)
# # SECONDS=$(date +%s)
# DATE=`date "+%Y%m%d.%H.%M.%S"`
# # SECONDS=$(date '+%H_%M')
# OUTPUT_DIR=/root/overnight_runs/kcore
# mkdir -p $OUTPUT_DIR
#
#
# GL_DATASET="twitter_graph_splits"
#
# NODES=16
# CPUS=8
# GL_KCORE_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES \
#     env CLASSPATH=$(hadoop classpath) \
#     $GRAPHLAB/release/toolkits/graph_analytics/kcore \
#     --graph=$HDFS/$GL_DATASET --format=snap --ncpus=$CPUS \
#     --graph_opts=ingress=random \
#     --kmin=1 --kmax=4"
#     # --savecores=$HDFS/kcore_del"
#
#
# GL_KCORE_FILE=$OUTPUT_DIR/graphlab_kcore_nodes$NODES-cpus$CPUS-$DATE
# echo $GL_KCORE_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_KCORE_FILE
# echo $GL_KCORE_COMMAND | tee -a $GL_KCORE_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /kcore_del* &> /dev/null
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GL_KCORE_COMMAND &>> $GL_KCORE_FILE
#   # hadoop dfs -rmr /kcore_del* &> /dev/null
#   echo Finished trial $xx
#   sleep 30
# done
#
#
# echo -e "\n\n FINISHED GRAPHLAB SMP\n\n"
#
# NODES=128
# CPUS=1
# GL_KCORE_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES \
#     env CLASSPATH=$(hadoop classpath) \
#     $GRAPHLAB/release/toolkits/graph_analytics/kcore \
#     --graph=$HDFS/$GL_DATASET --format=snap --ncpus=$CPUS \
#     --graph_opts=ingress=random \
#     --kmin=1 --kmax=4"
#     # --savecores=$HDFS/kcore_del"
#
#
# GL_KCORE_FILE=$OUTPUT_DIR/graphlab_kcore_nodes$NODES-cpus$CPUS-$DATE
# echo $GL_KCORE_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_KCORE_FILE
# echo $GL_KCORE_COMMAND | tee -a $GL_KCORE_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /kcore_del* &> /dev/null
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GL_KCORE_COMMAND &>> $GL_KCORE_FILE
#   # hadoop dfs -rmr /kcore_del* &> /dev/null
#   echo Finished trial $xx
#   sleep 30
# done
#
# echo -e "\n\n FINISHED GRAPHLAB SINGLE-THREADED\n\n"

##############################################################
# ALL KCORE UKUNION

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/overnight_runs/kcore
mkdir -p $OUTPUT_DIR

command=/mnt/graphx/bin/run-example
class=org.apache.spark.graphx.lib.Analytics
# DATASET="livejournal_graph_splits/part*"
GX_DATASET="ukunion_graph_splits/part*"
# DATASET="livejournal_graph"
NUMPARTS=128


# GRAPHX_KCORE_COMMAND="$command $class $SPARK kcore \
#   $HDFS/$GX_DATASET \
#   --numEPart=$NUMPARTS \
#   --kmax=4 --kmin=1"
#   # --partStrategy=EdgePartition2D"
#
# GRAPHX_KCORE_FILE=$OUTPUT_DIR/graphx_kcore_results_"$NUMPARTS"parts_$DATE
# echo $GRAPHX_KCORE_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $GRAPHX_KCORE_FILE
# cd /mnt/graphx
# # GRAPHX_SHA=`git rev-parse HEAD`
# GRAPHX_SHA=`git log -1 --decorate`
# cd -
# echo $GRAPHX_SHA >> $GRAPHX_KCORE_FILE
# echo $GRAPHX_KCORE_COMMAND | tee -a $GRAPHX_KCORE_FILE
# /mnt/graphx/sbin/stop-all.sh &> /dev/null
# sleep 10
# /mnt/graphx/sbin/stop-all.sh &> /dev/null
# /mnt/graphx/sbin/start-all.sh &> /dev/null
# sleep 10
# for xx in $(seq 1 $NUMTRIALS)
# do
#   # hadoop dfs -rmr /kcore_del
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GRAPHX_KCORE_COMMAND &>> $GRAPHX_KCORE_FILE
#   # hadoop dfs -rmr /kcore_del
#   echo Finished trial $xx
#   sleep 10
#   /mnt/graphx/sbin/stop-all.sh &> /dev/null
#   sleep 10
#   /mnt/graphx/sbin/stop-all.sh &> /dev/null
#   /mnt/graphx/sbin/start-all.sh &> /dev/null
#   sleep 10
#   # sleep 60
# done
#
# echo -e "\n\n FINISHED GRAPHX\n\n"


# GL_DATASET="ukunion_graph_splits"
#
# NODES=16
# CPUS=8
# GL_KCORE_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES \
#     env CLASSPATH=$(hadoop classpath) \
#     $GRAPHLAB/release/toolkits/graph_analytics/kcore \
#     --graph=$HDFS/$GL_DATASET --format=snap --ncpus=$CPUS \
#     --graph_opts=ingress=random \
#     --kmin=1 --kmax=4"
#     # --savecores=$HDFS/kcore_del"
#
#
# GL_KCORE_FILE=$OUTPUT_DIR/graphlab_kcore_nodes$NODES-cpus$CPUS-$DATE
# echo $GL_KCORE_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_KCORE_FILE
# echo $GL_KCORE_COMMAND | tee -a $GL_KCORE_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /kcore_del* &> /dev/null
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GL_KCORE_COMMAND &>> $GL_KCORE_FILE
#   # hadoop dfs -rmr /kcore_del* &> /dev/null
#   echo Finished trial $xx
#   sleep 30
# done
#
#
# echo -e "\n\n FINISHED GRAPHLAB SMP\n\n"

# NODES=128
# CPUS=1
# GL_KCORE_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES \
#     env CLASSPATH=$(hadoop classpath) \
#     $GRAPHLAB/release/toolkits/graph_analytics/kcore \
#     --graph=$HDFS/$GL_DATASET --format=snap --ncpus=$CPUS \
#     --graph_opts=ingress=random \
#     --kmin=1 --kmax=4"
#     # --savecores=$HDFS/kcore_del"
#
#
# GL_KCORE_FILE=$OUTPUT_DIR/graphlab_kcore_nodes$NODES-cpus$CPUS-$DATE
# echo $GL_KCORE_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_KCORE_FILE
# echo $GL_KCORE_COMMAND | tee -a $GL_KCORE_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /kcore_del* &> /dev/null
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GL_KCORE_COMMAND &>> $GL_KCORE_FILE
#   # hadoop dfs -rmr /kcore_del* &> /dev/null
#   echo Finished trial $xx
#   sleep 30
# done
#
# echo -e "\n\n FINISHED GRAPHLAB SINGLE-THREADED\n\n"


################################
# CC
# TIME=/usr/bin/time
# export SPARK=spark://$MASTERS:7077
# export HDFS=hdfs://$MASTERS:9000
#
# NUMTRIALS=3
# NOW=$(date)
# # SECONDS=$(date +%s)
# DATE=`date "+%Y%m%d.%H.%M.%S"`
# # SECONDS=$(date '+%H_%M')
# OUTPUT_DIR=/root/overnight_runs/cc
# mkdir -p $OUTPUT_DIR
# CC_ITERS=20
#
# command=/mnt/graphx/bin/run-example
# class=org.apache.spark.graphx.lib.DataflowPagerank
# GX_DATASET="ukunion_graph_splits/part*"
# # GX_DATASET="lj_graph_splits/part*"
# NUMPARTS=128
#
#
# CC_COMMAND="$command $class $SPARK \
#   $HDFS/$GX_DATASET \
#   $CC_ITERS $NUMPARTS cc"
#
# CC_FILE=$OUTPUT_DIR/naivespark_cc_results_"$NUMPARTS"parts_$DATE
# echo $CC_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $CC_FILE
# cd /mnt/graphx
# # GRAPHX_SHA=`git rev-parse HEAD`
# GRAPHX_SHA=`git log -1 --decorate`
# cd -
# echo $GRAPHX_SHA >> $CC_FILE
# echo $CC_COMMAND | tee -a $CC_FILE
# /mnt/graphx/sbin/stop-all.sh &> /dev/null
# sleep 10
# /mnt/graphx/sbin/stop-all.sh &> /dev/null
# /mnt/graphx/sbin/start-all.sh &> /dev/null
# sleep 10
# for xx in $(seq 1 $NUMTRIALS)
# do
#   # hadoop dfs -rmr /pr_del
#   $TIME -f "TOTAL_TIMEX: %e seconds" $CC_COMMAND &>> $CC_FILE
#   # hadoop dfs -rmr /pr_del
#   echo Finished trial $xx
#   sleep 10
#   /mnt/graphx/sbin/stop-all.sh &> /dev/null
#   sleep 10
#   /mnt/graphx/sbin/stop-all.sh &> /dev/null
#   /mnt/graphx/sbin/start-all.sh &> /dev/null
#   sleep 10
#   # sleep 60
# done
#
# echo -e "\n\n FINISHED NAIVE SPARK CONNECTED COMPONENTS\n\n"

##################################################################
# PAGERANK

TIME=/usr/bin/time
export SPARK=spark://$MASTERS:7077
export HDFS=hdfs://$MASTERS:9000

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/overnight_runs/pr
mkdir -p $OUTPUT_DIR
PR_ITERS=20

command=/mnt/graphx/bin/run-example
class=org.apache.spark.graphx.lib.DataflowPagerank
# GX_DATASET="twitter_graph_splits/part*"
GX_DATASET="ukunion_graph_splits/part*"
# GX_DATASET="lj_graph_splits/part*"
NUMPARTS=128


PR_COMMAND="$command $class $SPARK \
  $HDFS/$GX_DATASET \
  $PR_ITERS $NUMPARTS naive"

PR_FILE=$OUTPUT_DIR/naivespark_pr_results_"$NUMPARTS"parts_$DATE
echo $PR_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $PR_FILE
cd /mnt/graphx
# GRAPHX_SHA=`git rev-parse HEAD`
GRAPHX_SHA=`git log -1 --decorate`
cd -
echo $GRAPHX_SHA >> $PR_FILE
echo $PR_COMMAND | tee -a $PR_FILE
/mnt/graphx/sbin/stop-all.sh &> /dev/null
sleep 10
/mnt/graphx/sbin/stop-all.sh &> /dev/null
/mnt/graphx/sbin/start-all.sh &> /dev/null
sleep 10
for xx in $(seq 1 $NUMTRIALS)
do
  # hadoop dfs -rmr /pr_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $PR_COMMAND &>> $PR_FILE
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

echo -e "\n\n FINISHED NAIVE SPARK PAGERANK\n\n"



