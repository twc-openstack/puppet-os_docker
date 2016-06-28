#!/bin/bash -xve

BASEDIR=$(cd "$(dirname "$0")"; pwd)
EXCEPTIONDIR=$BASEDIR/exceptions

PROJECTS="designate glance heat keystone nova neutron cinder"
RELEASES="juno kilo liberty mitaka"

declare -A BRANCHES
BRANCHES=(
  ["juno"]="juno-eol"
  ["kilo"]="kilo-eol"
  ["liberty"]="stable/liberty"
  ["mitaka"]="stable/mitaka"
  ["newton"]="master"
)

# Optional arguments
# $1 - specific project to generate configs for
# $2 - specific release to generate project for
if [ $# -ge 1 ]; then
    $PROJECTS=$1
    if [ $# -eq 2 ]; then
        $RELEASES=$2
    fi
fi
echo "generating configs for ${PROJECTS} an ${RELEASES}"

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

    if [ -f $EXCEPTIONDIR/${PROJECT}-${RELEASE}.pre ]; then
      . $EXCEPTIONDIR/${PROJECT}-${RELEASE}.pre
    elif [ -f $EXCEPTIONDIR/${PROJECT}.pre ]; then
      . $EXCEPTIONDIR/${PROJECT}.pre
    fi

    if [ -f $EXCEPTIONDIR/${PROJECT}-${RELEASE} ]; then
      . $EXCEPTIONDIR/${PROJECT}-${RELEASE}
    elif [ -f $EXCEPTIONDIR/${PROJECT} ]; then
      . $EXCEPTIONDIR/${PROJECT}
    else
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

      # Some of the sample nova config files are _sample.conf instead of
      # .conf.sample which throws off the assumptions. in the config file
      # classes.
      for i in $(find $CONFDIR -name '*_sample.conf'); do
        mv $i $(dirname $i)/$(basename $i _sample.conf).conf.sample
      done

      rm -rf $CONFDIR/oslo-config-generator
      rsync -avP --delete --exclude 'README*.txt' --delete-excluded \
        $CONFDIR $BASEDIR/configs/$PROJECT/config/$RELEASE/
    fi

    if [ -f $EXCEPTIONDIR/${PROJECT}-${RELEASE}.post ]; then
      . $EXCEPTIONDIR/${PROJECT}-${RELEASE}.post
    elif [ -f $EXCEPTIONDIR/${PROJECT}.post ]; then
      . $EXCEPTIONDIR/${PROJECT}.post
    fi
  done
done
