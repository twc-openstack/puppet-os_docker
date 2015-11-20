# == Class: os_docker::nova::vncproxy
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
# os_docker::nova class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::nova class.
#
class os_docker::nova::vncproxy(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::nova::active_image_name,
  $active_image_tag  = $::os_docker::nova::active_image_tag,
){
  include ::os_docker::nova

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image   => "${active_image_name}:${active_image_tag}",
        command => '/usr/bin/nova-novncproxy',
        net     => 'host',
        volumes => [
          '/etc/nova:/etc/nova:ro',
          '/var/log/nova:/var/log/nova',
        ],
        tag => ['nova-docker'],
        service_prefix => '',
        manage_service => false,
        extra_parameters => ['--restart=always'],
      }

      $vncproxy_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'nova-vncproxy' => $vncproxy_resource } )
    }

    docker::command { '/usr/bin/nova-novncproxy':
      command => '/usr/bin/nova-novncproxy',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => [
        '/etc/nova:/etc/nova:ro',
        '/var/log/nova:/var/log/nova',
      ],
      tag     => ['nova-docker'],
    }
  }
}
