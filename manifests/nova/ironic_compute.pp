# == Class: os_docker::nova::ironic_compute
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.  The ironic_compute service is intended to be nova-compute
# running the ironic.IronicDriver. This container will expect an extra conf
# file in place called "/etc/nova/nova-ironic.conf" which contains the ironic
# specific nova-compute overrides.
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
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition the the normal
# volumes
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.  This can be used to ensure neutron-ovs-cleanup has
# already run before nova-compute is started.
#
class os_docker::nova::ironic_compute(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::nova::active_image_name,
  $active_image_tag  = $::os_docker::nova::active_image_tag,
  $extra_volumes     = [],
  $before_start      = false,
){

  $volumes = [
    '/etc/nova:/etc/nova:ro',
    '/dev:/dev',
    '/etc/ssh/ssh_known_hosts:/etc/ssh/ssh_known_hosts:ro',
    '/lib/modules:/lib/modules:ro',
    '/run/lock:/run/lock',
    '/var/log/nova:/var/log/nova',
    '/var/lib/nova:/var/lib/nova',
  ]

  $environment = [
    'OS_DOCKER_HOME_DIR=/var/lib/nova',
  ]

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/nova-compute --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-ironic.conf',
        net              => 'host',
        env              => $environment,
        privileged       => true,
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
        volumes          => concat($volumes, $extra_volumes),
        tag              => ['nova-docker'],
        before_start     => $before_start,
      }

      $compute_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'nova-compute-ironic' => $compute_resource } )
    }

    docker::command { '/usr/bin/nova-compute-ironic':
      command    => '/usr/bin/nova-compute --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-ironic.conf',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      env        => $environment,
      privileged => true,
      volumes    => concat($volumes, $extra_volumes),
      tag        => ['nova-docker'],
    }
  }
}
