
TIME=/usr/bin/time
export SPARK=spark://$MASTERS:7077
export HDFS=hdfs://$MASTERS:9000

NUMTRIALS=3
NOW=$(date)
# SECONDS=$(date +%s)
DATE=`date "+%Y%m%d.%H.%M.%S"`
# SECONDS=$(date '+%H_%M')
OUTPUT_DIR=/root/giraph_all
mkdir -p $OUTPUT_DIR
PR_ITERS=20

DATASET="/ukunion_graph_splits"


# ###################################################################
# # CONNECTED COMPONENTS
#
# INPUT_FMT="org.apache.giraph.io.formats.LongNullTextEdgeInputFormat"
# # INPUT_FMT="org.apache.giraph.io.formats.IntNullTextEdgeInputFormat"
# GIRAPH_CC_COMMAND="hadoop jar \
#     /root/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
#     org.apache.giraph.GiraphRunner org.apache.giraph.examples.ConnectedComponentsComputation \
#     -eif $INPUT_FMT \
#     -eip $HDFS/$DATASET/ \
#     -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
#     -op $HDFS/cc_del \
#     -w 127"
#
#
# GIRAPH_CC_FILE=$OUTPUT_DIR/giraph_cc_results_$DATE
# echo $GIRAPH_CC_FILE
# echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GIRAPH_CC_FILE
# echo $GIRAPH_CC_COMMAND | tee -a $GIRAPH_CC_FILE
# for xx in $(seq 1 $NUMTRIALS)
# do
#   hadoop dfs -rmr /cc_del
#   $TIME -f "TOTAL_TIMEX: %e seconds" $GIRAPH_CC_COMMAND &>> $GIRAPH_CC_FILE
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
# echo -e "\n\n FINISHED GIRAPH CONNECTED COMPONENTS\n\n"

###############################################################
# PAGERANK

GIRAPH_PR_COMMAND="hadoop jar \
  /root/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
  org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankComputation \
  -eif org.apache.giraph.io.formats.LongDefaultFloatTextEdgeInputFormat \
  -eip $HDFS/$DATASET/ \
  -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
  -op $HDFS/pr_del \
  -w 127 \
  -mc org.apache.giraph.examples.SimplePageRankComputation\$SimplePageRankMasterCompute"


GIRAPH_PR_FILE=$OUTPUT_DIR/giraph_pr_results_$DATE
echo $GIRAPH_PR_FILE
echo -e "\n\n\nStarting New Runs: $NOW \n\n\n" >> $GIRAPH_PR_FILE
echo $GIRAPH_PR_COMMAND | tee -a $GIRAPH_PR_FILE
for xx in $(seq 1 $NUMTRIALS)
do
  hadoop dfs -rmr /pr_del
  $TIME -f "TOTAL_TIMEX: %e seconds" $GIRAPH_PR_COMMAND &>> $GIRAPH_PR_FILE
  hadoop dfs -rmr /pr_del
  echo Finished trial $xx
  sleep 30
done

echo -e "\n\n FINISHED GIRAPH PAGERANK\n\n"

