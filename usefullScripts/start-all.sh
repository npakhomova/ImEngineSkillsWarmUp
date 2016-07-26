#!/bin/bash

HADOOP_DIR=${HADOOP_HOME:-"hadoop-2.7.1"}

OOZIE_VERSION=4.2.0
OOZIE_DIR=${OOZIE_HOME:-"oozie-$OOZIE_VERSION"}
OOZIE_TARGET="$OOZIE_DIR/distro/target/oozie-$OOZIE_VERSION-distro/oozie-$OOZIE_VERSION/"
OOZIE_BIN="$OOZIE_TARGET/bin"


${HADOOP_DIR}/sbin/start-dfs.sh
${HADOOP_DIR}/sbin/start-yarn.sh
${HADOOP_DIR}/sbin/mr-jobhistory-daemon.sh start historyserver

./run-additionalIDN.sh start 1 2 3

${OOZIE_BIN}/oozied.sh start