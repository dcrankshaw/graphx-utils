#!/usr/bin/env bash

source ~/spark-ec2/ec2-variables.sh
export GRAPHLAB=/mnt/graphlab
export HDFS=hdfs://$MASTERS:9000
export SPARK=spark://$MASTERS:7077
DATE=`date "+%Y%m%d.%H.%M.%S"`
TIME=/usr/bin/time
NUMTRIALS=2
NUMSTAGES=3
PR_ITERATIONS=5
DATASET="/twitter_graph_splits"
OUTBASE="/twitter_gp"
LOGBASEDIR="/root/twitter_pipeline_results_debug"
# LOGBASEDIR="/root/pipeline_debug_extract"
NODES=16
mkdir -p $LOGBASEDIR
GIRAPH_OUTPUT_FILE=$LOGBASEDIR/giraph_$DATE
echo $GIRAPH_OUTPUT_FILE
GL_OUTPUT_FILE=$LOGBASEDIR/graphlab_$DATE
echo $GL_OUTPUT_FILE
GRAPHX_OUTPUT_FILE=$LOGBASEDIR/graphx_$DATE
echo $GRAPHX_OUTPUT_FILE

graphlab_pipeline() {
  echo $GL_OUTPUT_FILE
  echo -e "\n\n\b Starting Pipeline\n" >> $GL_OUTPUT_FILE
  # $TIME -f "EXTRACT_TIMEX: %e seconds" $EXTRACT_GRAPH_COMMAND 2>&1 | tee -a $GL_OUTPUT_FILE
  for i in $(seq 1 $NUMSTAGES)
  do
    start=`date "+%s"`
    hadoop dfs -rm $HDFS$OUTBASE-edges_del_$i/_SUCCESS &> /dev/null
    GRAPHLAB_PR_COMMAND="mpiexec --hostfile /root/ephemeral-hdfs/conf/slaves -n $NODES \
        env CLASSPATH=$(hadoop classpath) \
      $GRAPHLAB/release/toolkits/graph_analytics/pagerank \
      --graph=$HDFS$OUTBASE-edges_del_$i \
      --format=snap --ncpus=8 --tol=0 --iterations=$PR_ITERATIONS \
      --saveprefix=$HDFS$OUTBASE-prs_del_$i"
    $TIME -f "PR_TIMEX %e" $GRAPHLAB_PR_COMMAND 2>&1 | tee -a $GL_OUTPUT_FILE
      
    GRAPHLAB_CC_COMMAND="mpiexec --hostfile /root/ephemeral-hdfs/conf/slaves -n $NODES \
      env CLASSPATH=$(hadoop classpath) \
      $GRAPHLAB/release/toolkits/graph_analytics/connected_component \
      --graph=$HDFS$OUTBASE-edges_del_$i --format=snap --ncpus=8 \
      --saveprefix=$HDFS$OUTBASE-ccs_del_$i"

    $TIME -f "CC_TIMEX %e" $GRAPHLAB_CC_COMMAND 2>&1 | tee -a $GL_OUTPUT_FILE

    ANALYZE_RESULTS_COMMAND="/root/graphx/bin/run-example \
      org.apache.spark.graphx.TwitterPipelineBenchmark \
      $SPARK analyze $HDFS$OUTBASE $i 0"

    $TIME -f "ANALYZE_TIMEX %e" $ANALYZE_RESULTS_COMMAND 2>&1 | tee -a $GL_OUTPUT_FILE
    # hadoop dfs -rmr $HDFS$OUTBASE-ccs_del_$i* &> /dev/null
    # hadoop dfs -rmr $HDFS$OUTBASE-prs_del_$i* &> /dev/null

    end=`date "+%s"`
    dur=$(( end - start ))
    echo TOTAL_TIMEX iteration $i $dur | tee -a $GL_OUTPUT_FILE
  done
}


giraph_pipeline() {
  echo $GIRAPH_OUTPUT_FILE
  echo -e "\n\n\b Starting Pipeline\n" >> $GIRAPH_OUTPUT_FILE
  for i in $(seq 1 $NUMSTAGES)
  do
    start=`date "+%s"`
    hadoop dfs -rm $HDFS$OUTBASE-edges_del_$i/_SUCCESS &> /dev/null

    GIRAPH_PR_COMMAND="hadoop jar \
      /root/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
      org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankComputation \
      -eif org.apache.giraph.io.formats.LongDefaultFloatTextEdgeInputFormat \
      -eip $HDFS$OUTBASE-edges_del_$i/ \
      -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
      -op $HDFS$OUTBASE-prs_del_$i \
      -w 63 \
      -mc org.apache.giraph.examples.SimplePageRankComputation\$SimplePageRankMasterCompute"

    $TIME -f "PR_TIMEX %e" $GIRAPH_PR_COMMAND 2>&1 | tee -a $GIRAPH_OUTPUT_FILE

    GIRAPH_CC_COMMAND="hadoop jar \
      /root/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-0.20.203.0-jar-with-dependencies.jar \
      org.apache.giraph.GiraphRunner org.apache.giraph.examples.ConnectedComponentsComputation \
      -eif org.apache.giraph.io.formats.LongNullTextEdgeInputFormat \
      -eip $HDFS$OUTBASE-edges_del_$i/ \
      -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat \
      -op $HDFS$OUTBASE-ccs_del_$i \
      -w 63"

    $TIME -f "CC_TIMEX %e" $GIRAPH_CC_COMMAND 2>&1 | tee -a $GIRAPH_OUTPUT_FILE

    ANALYZE_RESULTS_COMMAND="/root/graphx/bin/run-example \
      org.apache.spark.graphx.TwitterPipelineBenchmark \
      $SPARK analyze $HDFS$OUTBASE $i 1"

    $TIME -f "ANALYZE_TIMEX %e" $ANALYZE_RESULTS_COMMAND 2>&1 | tee -a $GIRAPH_OUTPUT_FILE
    # hadoop dfs -rmr $HDFS$OUTBASE-ccs_del_$i* &> /dev/null
    # hadoop dfs -rmr $HDFS$OUTBASE-prs_del_$i* &> /dev/null
    end=`date "+%s"`
    dur=$(( end - start ))
    echo TOTAL_TIMEX iteration $i $dur | tee -a $GIRAPH_OUTPUT_FILE
  done
}


graphx_pipeline() {

  echo $GRAPHX_OUTPUT_FILE
  echo -e "\n\n\b Starting Pipeline\n" >> $GRAPHX_OUTPUT_FILE

  GRAPHX_COMMAND="/root/graphx/bin/run-example \
    org.apache.spark.graphx.TwitterPipelineBenchmark \
    $SPARK graphx $HDFS$DATASET $NUMSTAGES \
    $PR_ITERATIONS 128"
    $TIME -f "TOTAL_PIPELINE_TIMEX_internal %e"  $GRAPHX_COMMAND 2>&1 | tee -a $GRAPHX_OUTPUT_FILE
}

rm  ~/GRAPHX_DONE
rm  ~/GRAPHLAB_DONE
rm  ~/GIRAPH_DONE


# ~/graphx/sbin/stop-all.sh
# sleep 10
# ~/graphx/sbin/start-all.sh
# sleep 10

# hadoop dfs -rmr $OUTBASE* &> /dev/null
# GRAPHX_COMMAND="/root/graphx/bin/run-example \
#   org.apache.spark.graphx.WikiPipelineBenchmark \
#   $SPARK graphx $HDFS$DATASET 0 \
#   $PR_ITERATIONS"
# $TIME -f "TOTAL_PIPELINE_TIMEX_internal: %e seconds"  $GRAPHX_COMMAND 2>&1 | tee -a $LOGBASEDIR/graphx2_extract_$DATE
# exit

# hadoop dfs -rmr $OUTBASE* &> /dev/null
# $TIME -f "EXTRACT_TIMEX: %e seconds" $EXTRACT_GRAPH_COMMAND 2>&1 | tee -a $LOGBASEDIR/extract2_$DATE


# Graphlab
# for t in $(seq 1 $NUMSTAGES)
# do
#   pstart=`date "+%s"`
#   graphlab_pipeline
#   pend=`date "+%s"`
#   pdur=$(( pend - pstart ))
#   echo "TOTAL_PIPELINE_TIMEX trial $t: $pdur" | tee -a $GL_OUTPUT_FILE
#   ~/graphx/sbin/stop-all.sh
#   sleep 10
#   ~/graphx/sbin/start-all.sh
#   sleep 10
#   hadoop dfs -mv $OUTBASE-edges_del_1 /no_del_twitter
#   hadoop dfs -rmr $OUTBASE* &> /dev/null
#   hadoop dfs -mv /no_del_twitter $OUTBASE-edges_del_1
# done
# touch ~/GRAPHLAB_DONE

# #Giraph
# for t in $(seq 1 $NUMSTAGES)
# do
#   pstart=`date "+%s"`
#   giraph_pipeline
#   pend=`date "+%s"`
#   pdur=$(( pend - pstart ))
#   echo "TOTAL_PIPELINE_TIMEX trial $t: $pdur" | tee -a $GIRAPH_OUTPUT_FILE
#   ~/graphx/sbin/stop-all.sh
#   sleep 10
#   ~/graphx/sbin/start-all.sh
#   sleep 10
#   hadoop dfs -mv $OUTBASE-edges_del_1 /no_del_twitter
#   hadoop dfs -rmr $OUTBASE* &> /dev/null
#   hadoop dfs -mv /no_del_twitter $OUTBASE-edges_del_1
# done
# touch ~/GIRAPH_DONE

#Graphx
for t in $(seq 1 $NUMSTAGES)
do
  pstart=`date "+%s"`
  graphx_pipeline
  pend=`date "+%s"`
  pdur=$(( pend - pstart ))
  echo "TOTAL_PIPELINE_TIMEX trial $t: $pdur" | tee -a $GRAPHX_OUTPUT_FILE
  ~/graphx/sbin/stop-all.sh
  sleep 10
  ~/graphx/sbin/start-all.sh
  sleep 10
done
touch ~/GRAPHX_DONE







