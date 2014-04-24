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
OUTPUT_DIR=/root/debug_pr_numbers
mkdir -p $OUTPUT_DIR
PR_ITERS=20

command=~/graphx/bin/run-example
class=org.apache.spark.graphx.lib.Analytics
# DATASET="livejournal_graph_splits/part*"
GX_DATASET="twitter_graph_splits/part*"
# DATASET="livejournal_graph"
NUMPARTS=64


GRAPHX_PR_COMMAND="$command $class $SPARK pagerank \
  $HDFS/$GX_DATASET \
  --numEPart=$NUMPARTS \
  --numIters=$PR_ITERS \
  --partStrategy=EdgePartition2D"

GRAPHX_PR_FILE=$OUTPUT_DIR/graphx_pr_results_"$NUMPARTS"parts_$DATE
echo $GRAPHX_PR_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $GRAPHX_PR_FILE
cd ~/graphx
GRAPHX_SHA=`git rev-parse HEAD`
cd -
echo $GRAPHX_SHA >> $GRAPHX_PR_FILE
echo $GRAPHX_PR_COMMAND | tee -a $GRAPHX_PR_FILE
~/graphx/sbin/stop-all.sh &> /dev/null
sleep 10
~/graphx/sbin/stop-all.sh &> /dev/null
~/graphx/sbin/start-all.sh &> /dev/null
sleep 10
for xx in $(seq 1 $NUMTRIALS)
do
  # hadoop dfs -rmr /pr_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $GRAPHX_PR_COMMAND &>> $GRAPHX_PR_FILE
  # hadoop dfs -rmr /pr_del
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

GL_PR_COMMAND="mpiexec --hostfile /root/ephemeral-hdfs/conf/slaves -n $NODES \
    env CLASSPATH=$(hadoop classpath) \
  $GRAPHLAB/release/toolkits/graph_analytics/pagerank \
  --graph=$HDFS/$GL_DATASET \
  --format=snap --ncpus=8 --tol=0 --iterations=$PR_ITERS \
  --saveprefix=$HDFS/pr_del"

GL_PR_FILE=$OUTPUT_DIR/graphlab_pr_results_$DATE
echo $GL_PR_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_PR_FILE
echo $GL_PR_COMMAND | tee -a $GL_PR_FILE
for xx in $(seq 1 $NUMTRIALS)
do
  hadoop dfs -rmr /pr_del* &> /dev/null
  $TIME -f "TOTAL_TIMEX: %e seconds" $GL_PR_COMMAND &>> $GL_PR_FILE
  hadoop dfs -rmr /pr_del* &> /dev/null
  echo Finished trial $xx
  sleep 30
done

echo -e "\n\n FINISHED GRAPHLAB\n\n" 
exit


# ########################### GIRAPH #####################################
# 
# DATASET="twitter_graph-splits"
#
# GIRAPH_PR_COMMAND="hadoop jar \
#   /root/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
#   org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankComputation \
#   -eif org.apache.giraph.io.formats.LongDefaultFloatTextEdgeInputFormat \
#   -eip $HDFS/$DATASET/ \
#   -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
#   -op $HDFS/pr_del \
#   -w 63 \
#   -mc org.apache.giraph.examples.SimplePageRankComputation\$SimplePageRankMasterCompute"
#
#
# GIRAPH_PR_FILE=$OUTPUT_DIR/giraph_pr_results_$DATE
# echo $GIRAPH_PR_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GIRAPH_PR_FILE
# echo $GIRAPH_PR_COMMAND | tee -a $GIRAPH_PR_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /pr_del
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GIRAPH_PR_COMMAND 2>&1 | tee -a $GIRAPH_PR_FILE
#   hadoop dfs -rmr /pr_del
#   echo Finished trial $xx
#   sleep 30
# done
#
# echo -e "\n\n FINISHED GIRAPH\n\n" | tee ~/GIRAPH_DONE

