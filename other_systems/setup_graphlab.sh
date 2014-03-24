#!/bin/bash

yum install -y openmpi-devel zlib-devel cmake
~/ephemeral-hdfs/bin/slaves.sh ln -s /usr/lib64/openmpi/bin/* /usr/bin/.
~/ephemeral-hdfs/bin/slaves.sh yum install -y openmpi-devel zlib-devel cmake
git clone https://github.com/jegonzal/graphlab.git /mnt/graphlab
cd /mnt/graphlab
git checkout spark-ec2-build
./configure
cd release/toolkits/graph_analytics
make -j8
cd /mnt
~/spark-ec2/copy-dir.sh graphlab

##### UPDATE THE HDFS NAMENODE
source ~/spark-ec2/ec2-variables.sh
export HDFS=hdfs://$MASTERS:9000
export GRAPHLAB=/mnt/graphlab


### Some experiments

# # 16 Node pagerank on a liveJournal single file
# time (mpiexec --hostfile ~/spark-ec2/slaves -n 16 env CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/pagerank --graph=$HDFS/soc-LiveJournal1.txt --format=snap --ncpus=8 --tol=0 --iterations=20)
#
# # 1 Node Pagerank on liveJournal single file
# time (mpiexec --hostfile ~/spark-ec2/slaves -n 1 env CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/pagerank --graph=$HDFS/soc-LiveJournal1.txt --format=snap --ncpus=8 --tol=0 --iterations=20)
#
# # 16 node triangle count on a liveJournal single file
# time (mpiexec --hostfile ~/spark-ec2/slaves -n 16 env CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/undirected_triangle_count --graph=$HDFS/soc-LiveJournal1.txt --format=snap --ncpus=8)
#
# # 1 Node triangle count on a liveJournal single file
# time (mpiexec --hostfile ~/spark-ec2/slaves -n 1 env CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/undirected_triangle_count --graph=$HDFS/soc-LiveJournal1.txt --format=snap --ncpus=8)
#
#
#
#
# ##### These two experiments need the uk web graph to be split into multiple files and you must remove the empty file created by spark when writing the folder in hdfs.
#
# # 16 Nodes pagerank on uk webgraph split into multiple files (Ask Dan for how to get this)
# time (mpiexec --hostfile ~/spark-ec2/slaves -n 16 env CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/pagerank --graph=$HDFS/uksplits --format=snap --ncpus=8 --tol=0 --iterations=20)
#
# ### Warning this currently crashes the cluster, we need a larger cluster to run this one -------------------
# # 16 Node triangle count on uk webgraph split into multiple files (again ask Dan)
# time (mpiexec --hostfile ~/spark-ec2/slaves -n 16 env CLASSPATH=$(hadoop classpath) $GRAPHLAB/release/toolkits/graph_analytics/undirected_triangle_count --graph=$HDFS/uksplits --format=snap --ncpus=8)
