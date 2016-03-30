#!/bin/bash -xve

# fork of update-configs for tesora-trove

BASEDIR=$(cd "$(dirname "$0")"; pwd)
PROJECTS="tesora-trove"
RELEASES="1.7 1.8"
declare -A BRANCHES
BRANCHES=(
  ["1.7"]="dev/1.7"
  ["1.8"]="dev/1.8"
)

. $BASEDIR/tox-venv/bin/activate

mkdir -p $BASEDIR/configs
for PROJECT in $PROJECTS; do
  cd $BASEDIR
  rm -rf $BASEDIR/git-tmp
  git clone https://github.com/Tesora/$PROJECT $BASEDIR/git-tmp
  for RELEASE in $RELEASES; do
    cd $BASEDIR/git-tmp
    git clean -f -x -d
    git checkout -f ${BRANCHES[$RELEASE]}
    if grep genconfig tox.ini; then
      tox -r -e genconfig
    fi
    mkdir -p $BASEDIR/configs/$PROJECT/config/$RELEASE
    if [ -d etc/$PROJECT ]; then
      CONFDIR=etc/$PROJECT/
    else
      CONFDIR=etc/
    fi

    # Some of the sample nova config files are _sample.conf instead of
    # .conf.sample which throws off the assumptions. in the config file
    # classes.
    for i in $(find $CONFDIR -name '*_sample.conf'); do
      mv $i $(dirname $i)/$(basename $i _sample.conf).conf.sample
    done

    rsync -avP --delete --exclude 'README*.txt' --delete-excluded \
      $CONFDIR $BASEDIR/configs/$PROJECT/config/$RELEASE/
  done
done
