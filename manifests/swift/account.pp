# == Define: os_docker::swift::account
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.
#
# === Parameters
#
# [*name*] (required) Name of container service to start and/or manage
# can be any of auditor|server|reconstructor|replicator|updater
# 
# [*manage_service*] (optional) Whether or not to manage the docker container
# for this service.  Default: true
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition tho the normal
# volumes
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.  This can be used to ensure neutron-ovs-cleanup has
# already run before swift-compute is started.
#
define os_docker::swift::account(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::swift::active_image_name,
  $active_image_tag  = $::os_docker::swift::active_image_tag,
  $extra_volumes     = [],
  $before_start      = false,
){
  include ::os_docker::swift
  validate_re($name, '^auditor|reaper|server|replicator$')

  $volumes = [
    '/etc/swift:/etc/swift:ro',
    '/srv/node:/srv/node',
    '/dev/log:/dev/log',
    '/lib/modules:/lib/modules:ro',
    '/run:/run',
    '/var/log/swift:/var/log/swift',
    '/var/lib/swift:/var/lib/swift',
    '/var/cache/swift:/var/cache/swift',
  ]

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/swift/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/swift',
  ]

  if $active_image_name {
    docker::command { "/usr/bin/swift-account-$name":
      command     => "/usr/bin/swift-account-$name",
      image       => "${active_image_name}:${active_image_tag}",
      net         => 'host',
      env         => $environment,
      privileged  => false,
      rm          => true,
      detach      => false,
      interactive => false,
      volumes     => concat($volumes, $extra_volumes),
      tag         => ['swift-docker'],
    }
  }
}
