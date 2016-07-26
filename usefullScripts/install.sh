#!/bin/bash

HADOOP_DIR=${HADOOP_HOME:-"hadoop-2.7.1"}
HADOOP_CONFIGS="$HADOOP_DIR/etc/hadoop"

function download_hadoop {
  if [ ! -f "hadoop-2.7.1.tar.gz" ]
    then
	curl http://mirror.olnevhost.net/pub/apache/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz > hadoop-2.7.1.tar.gz
    #  curl http://mdc2vr6159/installables/hadoopsparkoozie/hadoop-2.7.1.tar.gz > hadoop-2.7.1.tar.gz
  fi
  mkdir -p ${HADOOP_DIR}
  tar -C ${HADOOP_DIR} --strip-components=1 -xvvf hadoop-2.7.1.tar.gz
}

function backup_file {
  local FILENAME=$1
  if [ ! -f "$FILENAME.backup" ]
    then
      cp "$FILENAME" "$FILENAME.backup"
  fi
}

function generate_hdfs_config {
  backup_file "$HADOOP_CONFIGS/hdfs-site.xml"

  echo '''<?xml version="1.0" encoding="UTF-8"?>
  <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

  <configuration>
      <property>
          <name>dfs.replication</name>
          <value>3</value>
      </property>
  </configuration>
  ''' > "$HADOOP_CONFIGS/hdfs-site.xml"
}

function generate_core_config {
  backup_file "$HADOOP_CONFIGS/core-site.xml"

  local CONFIG='''<?xml version="1.0" encoding="UTF-8"?>
  <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

  <configuration>
      <property>
          <name>fs.defaultFS</name>
          <value>hdfs://localhost:9000</value>
      </property>

      <!-- OOZIE -->
      <property>
          <name>hadoop.proxyuser.$USER.hosts</name>
          <value>localhost</value>
      </property>
      <property>
          <name>hadoop.proxyuser.$USER.groups</name>
          <value>$USER</value>
      </property>
  </configuration>
  '''
  echo ${CONFIG//\$USER/$USER} > "$HADOOP_CONFIGS/core-site.xml"
}

function generate_yarn_config {
  backup_file "$HADOOP_CONFIGS/yarn-site.xml"

  echo '''<?xml version="1.0"?>
<configuration>

    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
     <property>
        <name>yarn.resourcemanager.scheduler.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
    </property>
</configuration>''' > "$HADOOP_CONFIGS/yarn-site.xml"
}

function generate_mapred_config {
  backup_file "$HADOOP_CONFIGS/mapred-site.xml"

  echo '''<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
  ''' > "$HADOOP_CONFIGS/mapred-site.xml"
}

function fix_java_home {
  backup_file "$HADOOP_CONFIGS/hadoop-env.sh"

  sed -i 's!export JAVA_HOME=${JAVA_HOME}!export JAVA_HOME=${JAVA_HOME:-"/usr/java/default"}!g' $HADOOP_CONFIGS/hadoop-env.sh
}

function format_hdfs {
  ${HADOOP_DIR}/bin/hdfs namenode -format -force
}

function start_hdfs_daemons {
  ${HADOOP_DIR}/sbin/start-dfs.sh
}

function start_yarn_daemons {
  ${HADOOP_DIR}/sbin/start-yarn.sh
}

function create_user_dirs {
  ${HADOOP_DIR}/bin/hdfs dfs -mkdir /user
  ${HADOOP_DIR}/bin/hdfs dfs -mkdir /user/`whoami`
}

run_datanode () {
  DN=$2
  export HADOOP_LOG_DIR=$DN_DIR_PREFIX$DN/logs
  export HADOOP_PID_DIR=$HADOOP_LOG_DIR
  DN_CONF_OPTS="\
  -Dhadoop.tmp.dir=$DN_DIR_PREFIX$DN \
  -Ddfs.datanode.address=0.0.0.0:5001$DN \
  -Ddfs.datanode.http.address=0.0.0.0:5008$DN \
  -Ddfs.datanode.ipc.address=0.0.0.0:5002$DN"
  $HADOOP_DIR/sbin/hadoop-daemon.sh --script bin/hdfs $1 datanode $DN_CONF_OPTS
}

function start_additional_datanodes {
  DN_DIR_PREFIX="$HADOOP_DIR/datanodes/"

  if [ ! -d $DN_DIR_PREFIX ]; then
    mkdir -p $DN_DIR_PREFIX
  fi

  for i in $*
  do
    run_datanode "start" $i
  done

}

function start_history_service {
    ${HADOOP_DIR}/sbin/mr-jobhistory-daemon.sh start historyserver
}

if [ -e "$HADOOP_DIR" ]
  then
    echo "hadoop exists"
  else
    download_hadoop
fi

generate_hdfs_config
generate_core_config
fix_java_home
format_hdfs
start_hdfs_daemons

create_user_dirs
generate_mapred_config
generate_yarn_config
start_yarn_daemons
start_history_service

start_additional_datanodes 1 2 3
