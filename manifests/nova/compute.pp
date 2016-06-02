# == Class: os_docker::nova::compute
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
# os_docker::nova class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::nova class.
#
# [*groups*] (optional) Groups that the nova user inside the container should
# be a member of.
#
# [*extra_volumes*] (optional) Extra docker volumes to mount inside the
# container.  This will be passed directly to docker in addition tho the normal
# volumes
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.  This can be used to ensure neutron-ovs-cleanup has
# already run before nova-compute is started.
#
class os_docker::nova::compute(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::nova::active_image_name,
  $active_image_tag  = $::os_docker::nova::active_image_tag,
  $groups            = ['libvirtd', 'ceph'],
  $extra_volumes     = [],
  $before_start      = false,
){
  include ::os_docker::nova

  $volumes = [
    '/etc/nova:/etc/nova:ro',
    '/etc/ceph:/etc/ceph:ro',
    # /etc/iscsi and /dev are needed for iscsi cinder volumes
    '/etc/iscsi:/etc/iscsi',
    '/dev:/dev',
    '/etc/ssh/ssh_known_hosts:/etc/ssh/ssh_known_hosts:ro',
    '/lib/modules:/lib/modules:ro',
    '/run/libvirt:/run/libvirt',
    '/run/openvswitch:/run/openvswitch',
    '/var/log/nova:/var/log/nova',
    '/var/lib/nova:/var/lib/nova',
    '/var/lib/libvirt:/var/lib/libvirt',
  ]

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/nova/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/nova',
  ]

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/nova-compute',
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
      create_resources('::docker::run', { 'nova-compute' => $compute_resource } )
    }

    # This directory exists to hold files the nova user needs to be able to
    # read.  The container is expected to ensure the nova user inside the
    # container is a member of the groups that own the files in the directory.
    file { '/etc/nova/groups':
      ensure  => 'directory',
      owner   => 'nova',
      group   => 'nova',
      mode    => '0755',
      purge   => true,
      recurse => true,
      force   => true,
    }

    $groups.each |$group| {
      file { "/etc/nova/groups/$group":
        ensure  => 'file',
        owner   => 'nova',
        group   => $group,
        content => '',
        require => [
          Package['ceph'],
          Package['libvirt-bin'],
        ],
      }
    }

    docker::command { '/usr/bin/nova-compute':
      command    => '/usr/bin/nova-compute',
      image      => "${active_image_name}:${active_image_tag}",
      net        => 'host',
      env        => $environment,
      privileged => true,
      volumes    => concat($volumes, $extra_volumes),
      tag        => ['nova-docker'],
    }
  }
}
