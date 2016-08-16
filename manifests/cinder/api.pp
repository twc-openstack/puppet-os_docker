# == Class: os_docker::cinder::api
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
# will invoke uwsgitop with the cinder-api uWSGI stats socket.
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
class os_docker::cinder::api(
  $manage_service       = true,
  $enable_uwsgitop      = true,
  $run_override         = {},
  $active_image_name    = $::os_docker::cinder::active_image_name,
  $active_image_tag     = $::os_docker::cinder::active_image_tag,
  $enable_monasca       = true,
  $monasca_event_socket = '/tmp/eventsocket',
  $before_start         = false,
){
  include ::os_docker::cinder

  if $active_image_name {
    $vols_default = [
      '/etc/cinder:/etc/cinder:ro',
      '/var/log/cinder:/var/log/cinder',
      '/var/lock/cinder:/var/lock/cinder',
      '/var/lib/cinder:/var/lib/cinder',
      '/var/run/monasca:/var/run/monasca',
    ]

    if $enable_monasca {
      $vols = concat($vols_default, "${monasca_event_socket}:${monasca_event_socket}")
    } else {
      $vols = $vols_default
    }

    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/cinder-api',
        net              => 'host',
        privileged       => true,
        volumes          => $vols,
        tag              => ['cinder-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
      }

      $api_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'cinder-api' => $api_resource } )
    }

    docker::command { '/usr/bin/cinder-api':
      command    => '/usr/bin/cinder-api',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      privileged => true,
      volumes    => $vols,
      tag        => ['cinder-docker'],
    }

    if $enable_uwsgitop {
      ::os_docker::uwsgitop { 'cinder-api':
        socket_path => '/var/log/cinder/cinder-api.stats',
        log_dir     => '/var/log/cinder',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
      ::os_docker::uwsgitop { 'cinder-metadata':
        socket_path => '/var/log/cinder/cinder-metadata.stats',
        log_dir     => '/var/log/cinder',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
    }
  }
}
