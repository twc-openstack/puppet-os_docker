#!/bin/bash -xve

BASEDIR=$(cd "$(dirname "$0")"; pwd)

docker build -t os_docker-updater .

docker run --rm \
  -h os-docker \
  -v $BASEDIR/update-configs.sh:/update-configs.sh  \
  -v $BASEDIR/../files/:/configs \
  os_docker-updater \
  /update-configs.sh

