# == Class: os_docker::ironic::inspector
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
# os_docker::ironic class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::ironic class.
#
class os_docker::ironic::inspector(
  $manage_service       = true,
  $run_override         = {},
  $active_image_name    = $::os_docker::ironic::active_image_name,
  $active_image_tag     = $::os_docker::ironic::active_image_tag,
){
  include ::os_docker::ironic

  if $active_image_name {
    $vols_default = [
      '/etc/ironic-inspector:/etc/ironic-inspector:ro',
      '/var/log/ironic-inspector:/var/log/ironic-inspector',
      '/var/lock/ironic-inspector:/var/lock/ironic-inspector',
      '/var/lib/ironic-inspector:/var/lib/ironic-inspector',
    ]

    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/ironic-inspector',
        net              => 'host',
        volumes          => $vols_default,
        tag              => ['ironic-inspector-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
      }

      $inspector_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'ironic-inspector' => $inspector_resource } )
    }

    docker::command { '/usr/bin/ironic-inspector':
      command    => '/usr/bin/ironic-inspector',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      privileged => true,
      volumes    => $vols_default,
      tag        => ['ironic-inspector-docker'],
    }
  }
}
