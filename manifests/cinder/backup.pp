# == Class: os_docker::cinder::backup
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.
#
# === Parameters
#
# [*manage_service*] (optional) Whether or not to manage the docker container
# for this service.  Default: true
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::cinder class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::cinder class.
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.
#
class os_docker::cinder::backup(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::cinder::active_image_name,
  $active_image_tag  = $::os_docker::cinder::active_image_tag,
  $before_start      = false,
){
  include ::os_docker::cinder

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image   => "${active_image_name}:${active_image_tag}",
        command => '/usr/bin/cinder-backup',
        net     => 'host',
        volumes => [
          '/etc/cinder:/etc/cinder:ro',
          '/var/log/cinder:/var/log/cinder',
        ],
        tag => ['cinder-docker'],
        service_prefix => '',
        manage_service => false,
        extra_parameters => ['--restart=always'],
      }

      $backup_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'cinder-backup' => $backup_resource } )
    }

    docker::command { '/usr/bin/cinder-backup':
      command => '/usr/bin/cinder-backup',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      backups => [
        '/etc/cinder:/etc/cinder:ro',
        '/var/log/cinder:/var/log/cinder',
      ],
      tag     => ['cinder-docker'],
    }
  }
}
