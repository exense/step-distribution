#!/bin/sh

ABSPATH=$(cd "$(dirname "$0")"; pwd)
cd ${ABSPATH}

JAVA_PATH=""
#JAVA_PATH="/usr/sbin/jdk-11.0.10/bin/"

JAVA_OPTS="${JAVA_OPTS} -Dlogback.configurationFile=./logback.xml -Dhttp.keepAlive=true -Dhttp.maxConnections=100"

${JAVA_PATH}java ${JAVA_OPTS} -cp ../lib/*: step.controller.ControllerServer -config=${ABSPATH}/../conf/step.properties