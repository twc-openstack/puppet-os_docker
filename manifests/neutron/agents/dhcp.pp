# == Class: os_docker::neutron::agents::dhcp
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
# already run before neutron-dhcp-agent is started.
#
# [*extra_parameters*] (optional) Additional parameters to pass to docker run
# when starting the service.  This will be used when run as from the
# command-line or when started as a service.
#
class os_docker::neutron::agents::dhcp(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::neutron::active_image_name,
  $active_image_tag  = $::os_docker::neutron::active_image_tag,
  $extra_volumes     = [],
  $before_start      = false,
  $extra_parameters  = [],
){
  include ::os_docker::neutron::params

  $volumes = concat(
    $os_docker::neutron::params::volumes,
    '/run/netns:/run/netns:shared',
    '/var/run/docker-sock/:/var/run/docker-sock',
    '/root/.docker:/root/.docker:ro',
    $extra_volumes,
  )

  $command = join([
    '/usr/bin/neutron-dhcp-agent',
    '--config-file=/etc/neutron/neutron.conf',
    '--config-file=/etc/neutron/dhcp_agent.ini',
  ], ' ')

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => $command,
        net              => 'host',
        env              => [
          'DOCKER_HOST=unix:///var/run/docker-sock/docker.sock'
        ],
        privileged       => true,
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => concat(['--restart=always'], $extra_parameters),
        volumes          => $volumes,
        tag              => ['neutron-docker'],
        before_start     => $before_start,
      }

      $dhcp_agent_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'neutron-dhcp-agent' => $dhcp_agent_resource } )
    }

    docker::command { '/usr/bin/neutron-dhcp-agent':
      command    => $command,
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      env              => [
        'DOCKER_HOST=unix:///var/run/docker-sock/docker.sock'
      ],
      privileged => true,
      extra_parameters => $extra_parameters,
      volumes    => $volumes,
      tag        => ['neutron-docker'],
    }

    $netns_cleanup_command = [
      'if [ -x /usr/bin/neutron-netns-cleanup ] ; then ',
      '/usr/bin/neutron-netns-cleanup ',
      '--config-file=/etc/neutron/neutron.conf ',
      '--config-file=/etc/neutron/dhcp_agent.ini >/dev/null 2>&1; ',
      'fi',
    ]

    cron { 'neutron-netns-cleanup for dhcp agent':
      command => join($netns_cleanup_command, ''),
      minute  => 30,
      # Needs to run as root since the wrapper around the command-line will
      # need to docker run this inside the container.
      user    => 'root'
    }
  }
}
