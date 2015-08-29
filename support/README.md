The files in this directory can be used to generate sample config files for
several OpenStack projects.  The run-update.sh script will build a Docker
container that contains the software needed to generate the sample config files
then invoke the update-configs.sh script inside of the container.  This will
place the updated configs in the files/<project>/<release> directory of the
module.
