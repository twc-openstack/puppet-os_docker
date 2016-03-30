#!/bin/bash -xve

BASEDIR=$(cd "$(dirname "$0")"; pwd)

docker build -t os_docker-updater .

COMMAND=/update-configs.sh

if [ $# -eq 1 ]; then
    if [ $1 -eq "tesora" ]; then
        COMMAND=/tesora-update-configs.sh
    fi
fi

docker run --rm \
  -h os-docker \
  -v $BASEDIR/update-configs.sh:/update-configs.sh  \
  -v $BASEDIR/../files/:/configs \
  os_docker-updater \
  $COMMAND
