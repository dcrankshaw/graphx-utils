#!/usr/bin/env bash

# /root/spark/sbin/stop-all.sh
# # rm -rf /root/default-spark
# # /root/spark/sbin/slaves.sh rm -rf /root/spark
# # mv ~/spark ~/default-spark
# cp ~/spark/conf/* ~/graphx/conf/
# ~/ephemeral-hdfs/bin/stop-all.sh
# ~/spark-ec2/copy-dir ~/ephemeral-hdfs/
# ~/ephemeral-hdfs/bin/start-all.sh
# mount /dev/sdj /wiki_full
# mount /dev/sdk /graph_data
#
# touch ~/HDFS_READY
# # hadoop dfs -put /wiki_full/data/enwiki-latest-pages-articles.xml /enwiki-latest
# # cd ~/incubator-spark; sbt/sbt assembly
# ~/graphx-utils/rebuild-graphx

#Setup graphlab
yum install -y openmpi-devel zlib-devel cmake
ln -s /usr/lib64/openmpi/bin/* /usr/bin/.
~/ephemeral-hdfs/bin/slaves.sh yum install -y openmpi-devel zlib-devel cmake
~/ephemeral-hdfs/bin/slaves.sh ln -s /usr/lib64/openmpi/bin/* /usr/bin/.
git clone https://github.com/dcrankshaw/graphlab.git /mnt/graphlab
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
# rm ~/HDFS_READY
