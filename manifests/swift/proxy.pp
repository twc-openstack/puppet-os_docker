# == Define: os_docker::swift::proxy
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.
#
# === Parameters
#
# [*name*] (required) Name of proxy service to start and/or manage
# can be any of auditor|server|reconstructor|replicator|updater
#
# [*release_name*] (required) Openstack release name (kilo, liberty) associated
# with this image.  Used to populate default configuration files.
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
# [*config_files*] (optional) Hash of filenames and parameters to the
# os_docker::config_file defined type.  Filenames should be relative to
# /etc/swift. Default: $::os_docker::swift::params::config_files
#
define os_docker::swift::proxy(
  $release_name,
  $active_image_name = $::os_docker::swift::active_image_name,
  $active_image_tag  = $::os_docker::swift::active_image_tag,
  $config_files      = $::os_docker::swift::params::config_files,
){
  include ::os_docker::swift
  include os_docker::swift::params

  if $active_image_name {
    os_docker::command { "/usr/bin/swift-proxy-server":
      command          => "/usr/bin/swift-proxy-server",
      image            => "${active_image_name}:${active_image_tag}",
      net              => 'host',
      env              => $os_docker::swift::params::environment,
      privileged       => false,
      rm               => true,
      detach           => false,
      extra_parameters => ['--pid=host', "--name=swift-proxy-server"],
      volumes          => $os_docker::swift::params::volumes,
      tag              => ['swift-docker'],
    }
  }

  os_docker::config_files { 'swift':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }
}
