#!/bin/bash -xve

# fork of update-configs for tesora-trove

BASEDIR=$(cd "$(dirname "$0")"; pwd)
PROJECTS="tesora-trove"
RELEASES="EE-1.8 EE-1.9"

. $BASEDIR/tox-venv/bin/activate

mkdir -p $BASEDIR/configs
for PROJECT in $PROJECTS; do
  cd $BASEDIR
  rm -rf $BASEDIR/git-tmp
  git clone https://github.com/Tesora-Release/$PROJECT $BASEDIR/git-tmp
  for RELEASE in $RELEASES; do
    cd $BASEDIR/git-tmp
    git clean -f -x -d
    git checkout -f $RELEASE
    if grep genconfig tox.ini; then
      tox -r -e genconfig
    fi
    mkdir -p $BASEDIR/configs/$PROJECT/config/$RELEASE
    if [ -d etc/$PROJECT ]; then
      CONFDIR=etc/$PROJECT/
    else
      CONFDIR=etc/
    fi

    rsync -avP --delete --exclude 'README*.txt' --exclude 'tests' \
      --delete-excluded \
      $CONFDIR $BASEDIR/configs/$PROJECT/config/$RELEASE/
  done
done
