# == Define: os_docker::swift::util
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.  This class creates a docker container wrapper for all of the
# supporting swift utilities.
#
# === Parameters
#
# [*title*] (required) Name of swift utility service wrapper to create
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
define os_docker::swift::util(
  $active_image_name = $::os_docker::swift::active_image_name,
  $active_image_tag  = $::os_docker::swift::active_image_tag,
){

  os_docker::command { "/usr/bin/${title}":
    command          => "/usr/bin/${title}",
    image            => "${active_image_name}:${active_image_tag}",
    net              => 'host',
    env              => [
      'OS_DOCKER_GROUP_DIR=/etc/swift/groups',
      'OS_DOCKER_HOME_DIR=/var/lib/swift',
    ],
    privileged       => false,
    rm               => true,
    detach           => false,
    extra_parameters => ["--name=${title}"],
    volumes => [
      '/etc/swift:/etc/swift:ro',
      '/var/cache/swift:/var/cache/swift',
      '/var/lock:/var/lock',
      '/srv/node:/srv/node',
      '/dev:/dev:ro',
    ],
    tag     => ['swift-docker'],
  }

}
