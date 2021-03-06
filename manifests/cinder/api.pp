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
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition tho the normal
# volumes
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
  $extra_volumes        = [],
  $before_start         = $::os_docker::cinder::before_start,
){
  include ::os_docker::cinder
  include ::os_docker::cinder::params

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/cinder-api',
        net              => 'host',
        privileged       => true,
        env              => $os_docker::cinder::params::environment,
        volumes          => concat($os_docker::cinder::params::volumes, $extra_volumes),
        tag              => ['cinder-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
        before_start     => $before_start,
      }

      $api_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'cinder-api' => $api_resource } )
    }

    docker::command { '/usr/bin/cinder-api':
      command    => '/usr/bin/cinder-api',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      privileged => true,
      env        => $os_docker::cinder::params::environment,
      volumes    => concat($os_docker::cinder::params::volumes, $extra_volumes),
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
