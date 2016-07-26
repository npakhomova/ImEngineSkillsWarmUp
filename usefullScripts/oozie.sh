#!/bin/bash

OOZIE_VERSION=4.2.0
OOZIE_DIR=${OOZIE_HOME:-"oozie-$OOZIE_VERSION"}
OOZIE_TARGET="$OOZIE_DIR/distro/target/oozie-$OOZIE_VERSION-distro/oozie-$OOZIE_VERSION/"
OOZIE_BIN="$OOZIE_TARGET/bin"

function download_oozie {
  if [ ! -f "oozie-$OOZIE_VERSION.tar.gz" ] ; then
    curl http://mdc2vr6159/installables/hadoopsparkoozie/oozie-${OOZIE_VERSION}.tar.gz > oozie-${OOZIE_VERSION}.tar.gz
  fi
  if [ ! -d "$OOZIE_DIR" ]
  then
    mkdir -p ${OOZIE_DIR}
    tar -C ${OOZIE_DIR} --strip-components=1 -xvvf oozie-${OOZIE_VERSION}.tar.gz
  fi
}

function build_oozie {
  $OOZIE_DIR/bin/mkdistro.sh -DskipTests -Puber -Phadoop-2 -Dhadoop.version=2.7.1 -Dspark.version=1.5.2
}

function patch_oozie {
  # Patching Oozie docs module
  local OOZIE_DOCS_POM=$(cat $OOZIE_DIR/docs/pom.xml)
  echo "${OOZIE_DOCS_POM//1.0-alpha-9.2y/1.0-alpha-9}" > $OOZIE_DIR/docs/pom.xml

  # Patching Oozie parent module
  local OOZIE_PARENT=$(cat $OOZIE_DIR/pom.xml)
  local LINE_TO_REPLACE=$(cat $OOZIE_DIR/pom.xml | grep -n -A 1 commons-io | grep version | cut -d "-" -f 1)
  local OUTPUT=$(sed  "${LINE_TO_REPLACE}s|.*|                <version>2.4</version>|" $OOZIE_DIR/pom.xml)
  echo "$OUTPUT" > $OOZIE_DIR/pom.xml
}

function download_tomcat {
  if [ ! -f $OOZIE_DIR/distro/downloads/tomcat-6.0.43.tar.gz ] ; then
    mkdir -p $OOZIE_DIR/distro/downloads/
    curl http://mdc2vr6159/installables/hadoopsparkoozie/tomcat-6.0.43.tar.gz > $OOZIE_DIR/distro/downloads/tomcat-6.0.43.tar.gz
  fi
}

function download_libext {
  if [ ! -d "$OOZIE_TARGET/libext" ] ; then
    mkdir -p $OOZIE_TARGET/libext
    curl http://mdc2vr6159/installables/hadoopsparkoozie/ext-2.2.zip > $OOZIE_TARGET/libext/ext-2.2.zip
  fi
}

function create_oozie_db {
  $OOZIE_BIN/oozie-setup.sh db create -run
}

function fix_oozie_war {
  zip -d $OOZIE_TARGET/oozie.war WEB-INF/lib/jsp-api-2.0.jar
  zip -d $OOZIE_TARGET/oozie-server/webapps/oozie.war WEB-INF/lib/jsp-api-2.0.jar
}

function start_oozie {
  $OOZIE_BIN/oozied.sh start
}

function deploy_sharelibs {
  $OOZIE_BIN/oozie-setup.sh sharelib create -fs hdfs://localhost:9000
}

download_oozie
patch_oozie
download_tomcat
build_oozie
download_libext
create_oozie_db
deploy_sharelibs
fix_oozie_war
start_oozie
