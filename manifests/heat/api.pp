# == Class: os_docker::heat::api
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
# will invoke uwsgitop with the heat-api uWSGI stats socket.
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::heat class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::heat class.
#
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition tho the normal
# volumes
#
class os_docker::heat::api(
  $manage_service    = true,
  $enable_uwsgitop   = true,
  $run_override      = {},
  $active_image_name = $::os_docker::heat::active_image_name,
  $active_image_tag  = $::os_docker::heat::active_image_tag,
  $extra_volumes     = [],
){
  include ::os_docker::heat
  include ::os_docker::heat::params

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/heat-api',
        net              => 'host',
        volumes          => concat($os_docker::heat::params::volumes, $extra_volumes),
        tag              => ['heat-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
      }

      $api_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'heat-api' => $api_resource } )
    }

    docker::command { '/usr/bin/heat-api':
      command => '/usr/bin/heat-api',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => concat($os_docker::heat::params::volumes, $extra_volumes),
      tag     => ['heat-docker'],
    }

    if $enable_uwsgitop {
      ::os_docker::uwsgitop { 'heat-api':
        socket_path => '/var/log/heat/heat-api.stats',
        log_dir     => '/var/log/heat',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
    }
  }
}
