# == Class: os_docker::ironic::api
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
# will invoke uwsgitop with the ironic-api uWSGI stats socket.
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::ironic class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::ironic class.
#
class os_docker::ironic::api(
  $manage_service       = true,
  $enable_uwsgitop      = true,
  $run_override         = {},
  $active_image_name    = $::os_docker::ironic::active_image_name,
  $active_image_tag     = $::os_docker::ironic::active_image_tag,
){
  include ::os_docker::ironic

  if $active_image_name {
    $vols_default = [
      '/etc/ironic:/etc/ironic:ro',
      '/var/log/ironic:/var/log/ironic',
      '/var/lock/ironic:/var/lock/ironic',
      '/var/lib/ironic:/var/lib/ironic',
    ]

    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/ironic-api',
        net              => 'host',
        privileged       => true,
        volumes          => $vols,
        tag              => ['ironic-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
      }

      $api_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'ironic-api' => $api_resource } )
    }

    docker::command { '/usr/bin/ironic-api':
      command    => '/usr/bin/ironic-api',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      privileged => true,
      volumes    => $vols,
      tag        => ['ironic-docker'],
    }
  }
}
