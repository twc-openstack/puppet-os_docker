# == Class: os_docker::nova::api
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
# [*enable_uwsgitop*] (optional) If true, then create a command-wrapper that
# will invoke uwsgitop with the nova-api uWSGI stats socket.
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
class os_docker::nova::api(
  $manage_service       = true,
  $enable_uwsgitop      = true,
  $run_override         = {},
  $active_image_name    = $::os_docker::nova::active_image_name,
  $active_image_tag     = $::os_docker::nova::active_image_tag,
  $enable_monasca       = true,
  $monasca_event_socket = '/tmp/eventsocket',
){
  include ::os_docker::nova

  if $active_image_name {
    $vols_default = [
      '/etc/nova:/etc/nova:ro',
      '/var/log/nova:/var/log/nova',
      '/var/lock/nova:/var/lock/nova',
      '/var/lib/nova:/var/lib/nova',
      '/etc/monasca:/etc/monasca',
    ]

    if $enable_monasca {
      $vols = concat($vols_default, "${monasca_event_socket}:${monasca_event_socket}")
    } else {
      $vols = $vols_default
    }

    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/nova-api',
        net              => 'host',
        privileged       => true,
        volumes          => $vols,
        tag              => ['nova-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
      }

      $api_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'nova-api' => $api_resource } )
    }

    docker::command { '/usr/bin/nova-api':
      command    => '/usr/bin/nova-api',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      privileged => true,
      volumes    => $vols,
      tag        => ['nova-docker'],
    }

    if $enable_uwsgitop {
      ::os_docker::uwsgitop { 'nova-api':
        socket_path => '/var/log/nova/nova-api.stats',
        log_dir     => '/var/log/nova',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
      ::os_docker::uwsgitop { 'nova-metadata':
        socket_path => '/var/log/nova/nova-metadata.stats',
        log_dir     => '/var/log/nova',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
    }
  }
}
