# == Class: os_docker::manila::share
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
class os_docker::manila::share(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::manila::active_image_name,
  $active_image_tag  = $::os_docker::manila::active_image_tag,
  $extra_volumes     = [],
  $before_start      = false,
){
  include ::os_docker::manila
  include ::os_docker::manila::params

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/manila-share',
        net              => 'host',
        env              => $os_docker::manila::params::environment,
        volumes          => concat($os_docker::manila::params::share_volumes, $extra_volumes),
        tag              => ['manila-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
        before_start     => $before_start,
      }

      $share_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'manila-share' => $share_resource } )
    }

    docker::command { '/usr/bin/manila-share':
      command => '/usr/bin/manila-share',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      env     => $os_docker::manila::params::environment,
      volumes => concat($os_docker::manila::params::share_volumes, $extra_volumes),
      tag     => ['manila-docker'],
    }
  }
}
