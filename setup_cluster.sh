#!/usr/bin/env bash

mount /dev/sdj /wiki_full
mount /dev/sdk /graph_data
/root/spark/sbin/stop-all.sh
# # rm -rf /root/backup_conf
cp -r /root/spark/conf /root/backup_conf
# # rm -rf /root/default-spark
/root/spark/sbin/slaves.sh rm -rf /root/spark
# # mv ~/spark ~/default-spark
# ############rm -rf /tmp/*
#
cp ~/spark/conf/* /wiki_full/graphx/conf/
# # cp ~/spark/conf/* ~/graphx/conf/
# # rm -rf /wiki_full/spark
mv ~/spark /wiki_full
# rm -rf /mnt/graphx
cp -r /wiki_full/graphx /mnt/
~/ephemeral-hdfs/bin/stop-all.sh
~/spark-ec2/copy-dir ~/ephemeral-hdfs/
~/ephemeral-hdfs/bin/start-all.sh
~/graphx-utils/rebuild-graphx
# exit

hadoop dfs -put /wiki_full/twitter/twitter_graph_splits/ /twitter_graph_splits
hadoop dfs -put /wiki_full/twitter/twitter_vertices /twitter_vertices
# cd ~/incubator-spark; sbt/sbt assembly

#### Setup graphlab
yum install -y openmpi-devel zlib-devel cmake
ln -s /usr/lib64/openmpi/bin/* /usr/bin/.
~/ephemeral-hdfs/bin/slaves.sh yum install -y openmpi-devel zlib-devel cmake
~/ephemeral-hdfs/bin/slaves.sh ln -s /usr/lib64/openmpi/bin/* /usr/bin/.
# git clone https://github.com/dcrankshaw/graphlab.git /mnt/graphlab
# cd /mnt/graphlab
# git checkout spark-ec2-build
# ./configure
# cd release/toolkits/graph_analytics
# make -j8
# cd /mnt
# rm -rf /mnt/graphlab
cp -r /wiki_full/graphlab /mnt
~/spark-ec2/copy-dir /mnt/graphlab

##### UPDATE THE HDFS NAMENODE
source ~/spark-ec2/ec2-variables.sh
export HDFS=hdfs://$MASTERS:9000
export GRAPHLAB=/mnt/graphlab
# rm ~/HDFS_READY
