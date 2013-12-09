#!/usr/bin/env bash


TIME=/usr/bin/time
NODES=16

NUMTRIALS=10
NOW=$(date)
SECONDS=$(date +%s)
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/benchmarking/${NODES}_cluster_wikipedia/
mkdir -p $OUTPUT_DIR
# 
# # for xx in $(seq 1 $NUMTRIALS)
# # do
# #   echo $xx
# # done
# # exit
# 
# 
# ######################### GraphLab #######################################
# 
# 
# GL_PR_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES env \
#     CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/pagerank \
#     --graph=$HDFS/wiki_parsed3_edges --format=snap --ncpus=8 --tol=0 --iterations=20"
# 
# 
# 
# GL_TRIANGLES_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES env \
#     CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/undirected_triangle_count \
#     --graph=$HDFS/twitter_splits --format=snap --ncpus=8"
# 
# GL_CC_COMMAND="mpiexec --hostfile /root/spark-ec2/slaves -n $NODES env \
#     CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/connected_component \
#     --graph=$HDFS/wiki_parsed3_edges --format=snap --ncpus=8"
# 
# # pagerank
# GL_PR_FILE=$OUTPUT_DIR/graphlab_pr_results.txt
# echo "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_PR_FILE
# echo $GL_PR_COMMAND | tee -a $GL_PR_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   $TIME -f "TOTAL: %e seconds" $GL_PR_COMMAND 2>&1 | tee -a $GL_PR_FILE
#   sleep 30
# done
# 
# 
# # connected components
# GL_CC_FILE=$OUTPUT_DIR/graphlab_cc_results.txt
# echo "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GL_CC_FILE
# echo $GL_CC_COMMAND | tee -a $GL_CC_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   $TIME -f "TOTAL: %e seconds" $GL_CC_COMMAND 2>&1 | tee -a $GL_CC_FILE
#   sleep 30
# done
# 
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
GIRAPH_CC_COMMAND="hadoop jar \
  /usr/local/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
  org.apache.giraph.GiraphRunner org.apache.giraph.examples.ConnectedComponentsComputation \
  -eif org.apache.giraph.io.formats.LongNullTextEdgeInputFormat \
  -eip /wiki_parsed3_edges \
  -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
  -op /cc_del \
  -w 64"
# 
# GIRAPH_PR_COMMAND="hadoop jar \
#   /usr/local/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
#   org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankComputation \
#   -eif org.apache.giraph.io.formats.LongDefaultFloatTextEdgeInputFormat \
#   -eip /wiki_parsed3_edges \
#   -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
#   -op /pr_del \
#   -w 64 \
#   -mc org.apache.giraph.examples.SimplePageRankComputation\$SimplePageRankMasterCompute"
# 
# # pagerank count
# GIRAPH_PR_FILE=$OUTPUT_DIR/giraph_pr_results.txt
# echo "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GIRAPH_PR_FILE
# echo $GIRAPH_PR_COMMAND | tee -a $GIRAPH_PR_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /pr_del
#   $TIME -f "TOTAL: %e seconds" $GIRAPH_PR_COMMAND 2>&1 | tee -a $GIRAPH_PR_FILE
#   hadoop dfs -rmr /pr_del
#   sleep 60
# done
# 

# 
# GIRAPH_CC_FILE=$OUTPUT_DIR/giraph_cc_results.txt
# echo "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GIRAPH_CC_FILE
# echo $GIRAPH_CC_COMMAND | tee -a $GIRAPH_CC_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /cc_del
#   $TIME -f "TOTAL: %e seconds" $GIRAPH_CC_COMMAND 2>&1 | tee -a $GIRAPH_CC_FILE
#   hadoop dfs -rmr /cc_del
#   sleep 60
# done

################################# DataFlow Pagerank #################################

DF_OUTPUT_DIR=/root/benchmarking/dataflow_pagerank_2
source /root/spark-ec2/ec2-variables.sh
mkdir -p $DF_OUTPUT_DIR

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
DF_PR_COMMAND="/root/graphx/run-example \
  org.apache.spark.graph.algorithms.DataflowPageRank \
  spark://$MASTERS:7077 hdfs://$MASTERS:9000/wiki_parsed3_edges"
DF_PR_FILE=$DF_OUTPUT_DIR/df_pr_results_wikipedia.txt
echo $DF_PR_COMMAND | tee -a $DF_PR_FILE
for xx in $(seq 1 5)
do
  $TIME -f "TOTAL: %e seconds" $DF_PR_COMMAND 2>&1 | tee -a $DF_PR_FILE
  sleep 60
done

/root/rebuild-graphx
sleep 200
/root/rebuild-graphx

# Twitter
DF_PR_COMMAND="/root/graphx/run-example \
  org.apache.spark.graph.algorithms.DataflowPageRank \
  spark://$MASTERS:7077 hdfs://$MASTERS:9000/twitter_splits"
DF_PR_FILE=$DF_OUTPUT_DIR/df_pr_results_twitter.txt
echo $DF_PR_COMMAND | tee -a $DF_PR_FILE
for xx in $(seq 1 5)
do
  $TIME -f "TOTAL: %e seconds" $DF_PR_COMMAND 2>&1 | tee -a $DF_PR_FILE
  sleep 60
done

exit







