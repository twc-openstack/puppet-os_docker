# == Define: os_docker::swift::object
#
# Creates a wrapper command around the object services passed in. These
# wrappers can be used to start the services directly in their own container
# which can be useful for debug purposes.
# Currently this includes creating the docker container and the os command
# to run it.
#
# === Parameters
#
# [*name*] (required) Name of object service to start and/or manage
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
define os_docker::swift::object(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::swift::active_image_name,
  $active_image_tag  = $::os_docker::swift::active_image_tag,
){
  include ::os_docker::swift
  include ::os_docker::swift::params
  validate_re($name, '^auditor|server|reconstructor|replicator|updater$')

  if $active_image_name {
    os_docker::command { "/usr/bin/swift-object-$name":
      command          => "/usr/bin/swift-object-$name",
      image            => "${active_image_name}:${active_image_tag}",
      net              => 'host',
      env              => $::os_docker::swift::params::environment,
      privileged       => false,
      rm               => true,
      detach           => false,
      extra_parameters => ['--pid=host', "--name=swift-object-${name}"],
      volumes          => $::os_docker::swift::params::volumes,
      tag              => ['swift-docker'],
    }
  }
}
