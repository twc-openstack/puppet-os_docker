# == Class: os_docker::cinder
#
# This class adds docker support to the cinder puppet module.  It supports
# pulling multiple docker images and switching between them by rewriting the
# init scripts and shell wrappers and then restarting the services.  It's
# expected that the images in use will be configured via hiera and that
# switching between active images will be done in the same way, but nothing
# prevents static configuration either.
#
# === Parameters
#
# [*release_name*] (required) Openstack release name (kilo, liberty) associated
# with this image.  Used to populate default configuration files.
#
# [*active_image_name*] (required) Name of the image to use by default for all
# cinder services.  This can overridden on a per service basis. This image will
# be used for the cinder-manage script.
#
# [*active_image_tag*] (optional) Tag of the active_image_name to use.
# Default: 'latest'
#
# [*active_image_overrides*] (optional) Extra parameters to pass into
# Docker::Image when creating the active image resource.  Default: {}
#
# [*extra_images*] (optional) Additional images associated with this service
# that should be pulled.  This is passed directly to Docker::Image.  This may
# be used to prepopulate new images.  Default: {}
#
# [*config_files*] (optional) Hash of filenames and parameters to the
# os_docker::config_file defined type.  Filenames should be relative to
# /etc/cinder. Default: $::os_docker::cinder::params::config_files
#
# [*before_start*] (optional) Shell script part that will be run before the
# service is started.
#
# [*enable_iscsi*] (optional) If you are using an iSCSI related backend for
# cinder you will need to set this flag to true.  It will set up extra volumes
# in order for the iSCSI devices to be visible inside the container.
#
# [*enable_nfs*] (optional) If you are using the NFS backend for cinder you
# will need to set this flag to true.  It will set up extra volumes in order
# for the NFS mounts to be visible outside of the container.
#
class os_docker::cinder(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::cinder::params::config_files,

  $before_start           = '',
  $enable_iscsi           = false,
  $enable_nfs             = false,
) inherits os_docker::cinder::params {

  file { $::os_docker::cinder::params::managed_dirs:
    ensure => directory,
    owner  => 'cinder',
    group  => 'cinder',
    mode   => '0755',
    before => Anchor['cinder::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'cinder-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/cinder-manage':
    command => '/usr/bin/cinder-manage',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    env     => $os_docker::cinder::params::environment,
    volumes => $os_docker::cinder::params::volumes,
    tag     => ['cinder-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['cinder::install::begin']
  -> Package<| tag == 'cinder-package' |>
  -> Docker::Image<| tag == 'cinder-docker' |>
  -> Docker::Command<| tag == 'cinder-docker' |>
  ~> Anchor['cinder::install::end']

  Anchor['cinder::service::begin']
  ~> Docker::Run<| tag == 'cinder-docker' |>
  ~> Anchor['cinder::service::end']

  Docker::Run<| tag == 'cinder-docker' |>
  -> Service<| tag == 'cinder-service' |>

  os_docker::config_files { 'cinder':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The cinder user isn't a docker user and this runs as the cinder user inside the
  # container anyway.
  Exec<| title == 'cinder-manage db_sync' |> {
    user => 'root',
  }
}
