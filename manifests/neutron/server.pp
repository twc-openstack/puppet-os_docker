# == Class: os_docker::neutron::server
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
# os_docker::neutron class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::neutron class.
#
# [*groups*] (optional) Groups that the neutron user inside the container should
# be a member of.
#
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition tho the normal
# volumes
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.  This can be used to ensure neutron-ovs-cleanup has
# already run before neutron-server is started.
#
class os_docker::neutron::server(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::neutron::active_image_name,
  $active_image_tag  = $::os_docker::neutron::active_image_tag,
  $extra_volumes     = [],
  $before_start      = false,
){
  include ::os_docker::neutron::params

  $command = join([
    '/usr/bin/neutron-server',
    '--config-file=/etc/neutron/neutron.conf',
    '--config-file=/etc/neutron/plugin.ini',
  ], ' ')

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => $command,
        net              => 'host',
        privileged       => false,
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
        volumes          => concat($os_docker::neutron::params::volumes, $extra_volumes),
        tag              => ['neutron-docker'],
        before_start     => $before_start,
      }

      $server_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'neutron-server' => $server_resource } )
    }

    docker::command { '/usr/bin/neutron-server':
      command    => '/usr/bin/neutron-server',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      env        => $environment,
      privileged => true,
      volumes          => concat($os_docker::neutron::params::volumes, $extra_volumes),
      tag        => ['neutron-docker'],
    }
  }
}
