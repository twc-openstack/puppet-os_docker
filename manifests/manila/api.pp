# == Class: os_docker::manila::api
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
# will invoke uwsgitop with the manila-api uWSGI stats socket.
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::manila class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::manila class.
#
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition tho the normal
# volumes
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.
#
class os_docker::manila::api(
  $manage_service       = true,
  $enable_uwsgitop      = true,
  $run_override         = {},
  $active_image_name    = $::os_docker::manila::active_image_name,
  $active_image_tag     = $::os_docker::manila::active_image_tag,
  $enable_monasca       = true,
  $monasca_event_socket = '/tmp/eventsocket',
  $extra_volumes        = [],
  $before_start         = false,
){
  include ::os_docker::manila
  include ::os_docker::manila::params

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/manila-api',
        net              => 'host',
        privileged       => true,
        env              => $os_docker::manila::params::environment,
        volumes          => concat($os_docker::manila::params::volumes, $extra_volumes),
        tag              => ['manila-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
        before_start     => $before_start,
      }

      $api_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'manila-api' => $api_resource } )
    }

    docker::command { '/usr/bin/manila-api':
      command    => '/usr/bin/manila-api',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      privileged => true,
      env        => $os_docker::manila::params::environment,
      volumes    => concat($os_docker::manila::params::volumes, $extra_volumes),
      tag        => ['manila-docker'],
    }

    if $enable_uwsgitop {
      ::os_docker::uwsgitop { 'manila-api':
        socket_path => '/var/log/manila/manila-api.stats',
        log_dir     => '/var/log/manila',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
      ::os_docker::uwsgitop { 'manila-metadata':
        socket_path => '/var/log/manila/manila-metadata.stats',
        log_dir     => '/var/log/manila',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
    }
  }
}
