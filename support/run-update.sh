#!/bin/bash -xve

BASEDIR=$(cd "$(dirname "$0")"; pwd)

docker build -t os_docker-updater .

COMMAND=/update-configs.sh

if [ $# -eq 1 ]; then
    if [ "$1" == "tesora" ]; then
        COMMAND=/tesora-update-configs.sh
    fi
fi

docker run --rm \
  --hostname os-docker \
  -v $BASEDIR/$COMMAND:/$COMMAND  \
  -v $BASEDIR/exceptions/:/exceptions/ \
  -v $BASEDIR/../files/:/configs \
  os_docker-updater \
  $COMMAND
