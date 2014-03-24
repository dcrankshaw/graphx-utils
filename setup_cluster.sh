#!/usr/bin/env bash

/root/spark/sbin/stop-all.sh
rm -rf /root/default-spark
/root/spark/sbin/slaves.sh rm -rf /root/spark
# mv ~/spark ~/default-spark
cp ~/spark/conf/* ~/graphx/conf/
~/ephemeral-hdfs/bin/stop-all.sh
~/spark-ec2/copy-dir ~/ephemeral-hdfs/
~/ephemeral-hdfs/bin/start-all.sh
mount /dev/sdj /wiki_full
hadoop dfs -put /wiki_full/data/enwiki-latest-pages-articles.xml /enwiki-latest
# cd ~/incubator-spark; sbt/sbt assembly
~/graphx-utils/rebuild-graphx

