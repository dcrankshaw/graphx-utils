#!/usr/bin/env bash


TIME=/usr/bin/time
NODES=16

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/debug_cc
mkdir -p $OUTPUT_DIR

command=~/graphx/bin/run-example
class=org.apache.spark.graphx.lib.Analytics
# DATASET="livejournal_graph_splits/part*"
DATASET="twitter_graph_splits/part*"
# DATASET="livejournal_graph"
NUMPARTS=64

export HDFS=hdfs://$MASTERS:9000

###################### GraphX #################################
GRAPHX_CC_COMMAND="$command $class spark://$MASTERS:7077 cc \
  $HDFS/$DATASET \
  --numEPart=$NUMPARTS \
  --dynamic=true"

GRAPHX_CC_FILE=$OUTPUT_DIR/graphx_cc_results_"$NUMPARTS"parts_$DATE
echo $GRAPHX_CC_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" | tee -a $GRAPHX_CC_FILE
echo $GRAPHX_CC_COMMAND | tee -a $GRAPHX_CC_FILE
~/graphx/sbin/stop-all.sh &> /dev/null
sleep 10
~/graphx/sbin/stop-all.sh &> /dev/null
~/graphx/sbin/start-all.sh &> /dev/null
sleep 10
for xx in $(seq 1 $NUMTRIALS)
do
  # hadoop dfs -rmr /cc_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $GRAPHX_CC_COMMAND &>> $GRAPHX_CC_FILE
  # hadoop dfs -rmr /cc_del
  echo Finished iter $xx
  sleep 10
  ~/graphx/sbin/stop-all.sh &> /dev/null
  sleep 10
  ~/graphx/sbin/stop-all.sh &> /dev/null
  ~/graphx/sbin/start-all.sh &> /dev/null
  sleep 10
  # sleep 60
done

echo -e "\n\n FINISHED GRAPHX\n\n" | tee ~/GRAPHX_DONE

# ######################### GraphLab #######################################

GL_DATASET="livejournal_graph_splits"
GL_CC_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES env \
    CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/connected_component \
    --graph=$HDFS/$GL_DATASET --format=snap --ncpus=8 \
    --saveprefix=$HDFS/cc_del"

GL_CC_FILE=$OUTPUT_DIR/graphlab_cc_results_$DATE
echo $GL_CC_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_CC_FILE
echo $GL_CC_COMMAND | tee -a $GL_CC_FILE
for xx in $(seq 1 $NUMTRIALS)
do
  hadoop dfs -rmr /cc_del* &> /dev/null
  $TIME -f "TOTAL_TIMEX: %e seconds" $GL_CC_COMMAND 2>&1 | tee -a $GL_CC_FILE
  hadoop dfs -rmr /cc_del* &> /dev/null
  echo Finished iter $xx
  sleep 30
done

echo -e "\n\n FINISHED GRAPHLAB\n\n" | tee ~/GRAPHLAB_DONE


# 
# # triangle count
# # GL_TRIANGLES_FILE=$OUTPUT_DIR/graphlab_triangles_results.txt
# # echo "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_TRIANGLES_FILE
# # echo $GL_TRIANGLES_COMMAND | tee -a $GL_TRIANGLES_FILE
# # for xx in $(seq 1 $NUMTRIALS)
# # do
# #   $TIME -f "TOTAL: %e seconds" $GL_TRIANGLES_COMMAND 2>&1 | tee -a $GL_TRIANGLES_FILE
# #   sleep 30
# # done
# 
# 
# ########################### GIRAPH #####################################
# 
# DATASET="/livejournal_graph"
# DATASET="/livejournal_graph"
# # INPUT_FMT="org.apache.giraph.io.formats.LongNullTextEdgeInputFormat"
# INPUT_FMT="org.apache.giraph.io.formats.IntNullTextEdgeInputFormat"
# GIRAPH_CC_COMMAND="hadoop jar \
#   /root/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
#   org.apache.giraph.GiraphRunner org.apache.giraph.examples.ConnectedComponentsComputation \
#   -eif $INPUT_FMT \
#   -eip $DATASET \
#   -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
#   -op /cc_del \
#   -w 63"
#
#
# GIRAPH_CC_FILE=$OUTPUT_DIR/giraph_cc_results_$DATE
# echo $GIRAPH_CC_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GIRAPH_CC_FILE
# echo $GIRAPH_CC_COMMAND | tee -a $GIRAPH_CC_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /cc_del
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GIRAPH_CC_COMMAND 2>&1 | tee -a $GIRAPH_CC_FILE
#   hadoop dfs -rmr /cc_del
#   echo Finished iter $xx
#   sleep 30
#   # ~/ephemeral-hdfs/bin/stop-all.sh &> /dev/null
#   # sleep 10
#   # ~/ephemeral-hdfs/bin/stop-all.sh &> /dev/null
#   # sleep 10
#   # ~/ephemeral-hdfs/bin/start-all.sh &> /dev/null
#   # sleep 10
# done
#
# echo -e "\n\n FINISHED GIRAPH\n\n" | tee ~/GIRAPH_DONE

################################# DataFlow Pagerank #################################

# DF_OUTPUT_DIR=/root/benchmarking/dataflow_pagerank_2
# source /root/spark-ec2/ec2-variables.sh
# mkdir -p $DF_OUTPUT_DIR

# /root/rebuild-graphx
# # Livejournal
# cd /root/graphx
# DF_PR_COMMAND="/root/graphx/run-example \
#   org.apache.spark.graph.algorithms.DataflowPageRank \
#   spark://$MASTERS:7077 hdfs://$MASTERS:9000/livejournal"
# DF_PR_FILE=$DF_OUTPUT_DIR/df_pr_results_livejournal.txt
# echo $DF_PR_COMMAND | tee -a $DF_PR_FILE
# for xx in $(seq 1 5)
# do
#   $TIME -f "TOTAL: %e seconds" $DF_PR_COMMAND 2>&1 | tee -a $DF_PR_FILE
#   sleep 60
# done
# # /root/rebuild-graphx -no
# 

# Wikipedia
# DF_PR_COMMAND="/root/graphx/run-example \
#   org.apache.spark.graph.algorithms.DataflowPageRank \
#   spark://$MASTERS:7077 hdfs://$MASTERS:9000/wiki_parsed3_edges"
# DF_PR_FILE=$DF_OUTPUT_DIR/df_pr_results_wikipedia.txt
# echo $DF_PR_COMMAND | tee -a $DF_PR_FILE
# for xx in $(seq 1 5)
# do
#   $TIME -f "TOTAL: %e seconds" $DF_PR_COMMAND 2>&1 | tee -a $DF_PR_FILE
#   sleep 60
# done
#
# /root/rebuild-graphx
# sleep 200
# /root/rebuild-graphx
#
# # Twitter
# DF_PR_COMMAND="/root/graphx/run-example \
#   org.apache.spark.graph.algorithms.DataflowPageRank \
#   spark://$MASTERS:7077 hdfs://$MASTERS:9000/twitter_splits"
# DF_PR_FILE=$DF_OUTPUT_DIR/df_pr_results_twitter.txt
# echo $DF_PR_COMMAND | tee -a $DF_PR_FILE
# for xx in $(seq 1 5)
# do
#   $TIME -f "TOTAL: %e seconds" $DF_PR_COMMAND 2>&1 | tee -a $DF_PR_FILE
#   sleep 60
# done
#
# exit







