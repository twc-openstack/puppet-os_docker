# == Class: os_docker::cinder::volume
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
# [*enable_nfs*] (optional) If you are using the NFS backend for cinder you
# will need to set this flag to true.  It will set up extra volumes in order
# for the NFS mounts to be visible outside of the container.
#
class os_docker::cinder::volume(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::os_docker::cinder::active_image_name,
  $active_image_tag  = $::os_docker::cinder::active_image_tag,
  $extra_volumes     = [],
  $before_start      = false,
  $enable_nfs        = false,
){
  include ::os_docker::cinder
  include ::os_docker::cinder::params

  if $enable_nfs {
    $nfs_volumes = [ '/var/lib/cinder/mnt:/var/lib/cinder/mnt:shared' ]
    $nfs_onstart = "mount --make-shared /var/lib/cinder/mnt"

    mount { '/var/lib/cinder/mnt':
      ensure  => 'mounted',
      device  => '/var/lib/cinder/mnt',
      fstype  => 'none',
      options => 'rw,bind',
      require => File['/var/lib/cinder/mnt'],
    }
  } else {
    $nfs_volumes = [ ]
    $nfs_onstart = ''
  }

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image            => "${active_image_name}:${active_image_tag}",
        command          => '/usr/bin/cinder-volume',
        net              => 'host',
        env              => $os_docker::cinder::params::environment,
        volumes          => concat($os_docker::cinder::params::volumes, $nfs_volumes, $extra_volumes),
        tag              => ['cinder-docker'],
        service_prefix   => '',
        manage_service   => false,
        extra_parameters => ['--restart=always'],
        before_start     => join([$before_start, $nfs_onstart], "\n"),
      }

      $volume_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'cinder-volume' => $volume_resource } )
    }

    docker::command { '/usr/bin/cinder-volume':
      command => '/usr/bin/cinder-volume',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      env     => $os_docker::cinder::params::environment,
      volumes => concat($os_docker::cinder::params::volumes, $nfs_volumes, $extra_volumes),
      tag     => ['cinder-docker'],
    }
  }
}
