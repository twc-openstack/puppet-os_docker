#!/bin/bash -xve

BASEDIR=$(cd "$(dirname "$0")"; pwd)
PROJECTS="designate glance heat keystone nova"
RELEASES="juno kilo liberty"
declare -A BRANCHES
BRANCHES=(
  ["juno"]="stable/juno"
  ["kilo"]="stable/kilo"
  ["liberty"]="stable/liberty"
  ["mitaka"]="master"
)

. $BASEDIR/tox-venv/bin/activate

mkdir -p $BASEDIR/configs
for PROJECT in $PROJECTS; do
  cd $BASEDIR
  rm -rf $BASEDIR/git-tmp
  git clone https://github.com/openstack/$PROJECT $BASEDIR/git-tmp
  for RELEASE in $RELEASES; do
    cd $BASEDIR/git-tmp
    git clean -f -x -d
    git checkout -f ${BRANCHES[$RELEASE]}
    if grep genconfig tox.ini; then
      # Work around bug in glance stable/kilo branch
      perl -i -pe 's!.*oslo-config-generator.*glance-search.conf.*$!!' tox.ini
      tox -r -e genconfig
    fi
    mkdir -p $BASEDIR/configs/$PROJECT/config/$RELEASE
    if [ -d etc/$PROJECT ]; then
      CONFDIR=etc/$PROJECT/
    else
      CONFDIR=etc/
    fi
    rsync -avP --delete --exclude 'README*.txt' --delete-excluded \
      $CONFDIR $BASEDIR/configs/$PROJECT/config/$RELEASE/
  done
done
