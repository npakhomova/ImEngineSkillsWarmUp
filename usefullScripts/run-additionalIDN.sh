#!/bin/sh
# This is used for starting multiple datanodes on the same machine.
# run it from hadoop-dir/ just like 'bin/hadoop'

#Usage: run-additionalDN.sh [start|stop] dnnumber
#e.g. run-datanode.sh start 2

HADOOP_DIR=${HADOOP_HOME:-"hadoop-2.7.1"}
HADOOP_CONFIGS="$HADOOP_DIR/etc/hadoop"

DN_DIR_PREFIX="$HADOOP_DIR/datanodes/"

if [ ! -d $DN_DIR_PREFIX ]; then
    mkdir -p $DN_DIR_PREFIX
fi

run_datanode () {
DN=$2
export HADOOP_LOG_DIR=$DN_DIR_PREFIX$DN/logs
export HADOOP_PID_DIR=$HADOOP_LOG_DIR
DN_CONF_OPTS="\
-Dhadoop.tmp.dir=$DN_DIR_PREFIX$DN \
-Ddfs.datanode.address=0.0.0.0:5001$DN \
-Ddfs.datanode.http.address=0.0.0.0:5008$DN \
-Ddfs.datanode.ipc.address=0.0.0.0:5002$DN"
    ${HADOOP_DIR}/sbin/hadoop-daemon.sh --script bin/hdfs $1 datanode $DN_CONF_OPTS
}

cmd=$1
shift;

for i in $*
do
run_datanode  $cmd $i
done
