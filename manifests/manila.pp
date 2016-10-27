# == Class: os_docker::manila
#
# This class adds docker support to the manila puppet module.  It supports
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
# manila services.  This can overridden on a per service basis. This image will
# be used for the manila-manage script.
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
# /etc/manila. Default: $::os_docker::manila::params::config_files
#
class os_docker::manila(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::manila::params::config_files,
  $groups                 = ['ceph'],
) inherits os_docker::manila::params {

  # This directory exists to hold files the manila user needs to be able to
  # read.  The container is expected to ensure the manila user inside the
  # container is a member of the groups that own the files in the directory.
  file { '/etc/manila/groups':
    ensure  => 'directory',
    owner   => 'manila',
    group   => 'manila',
    mode    => '0755',
    purge   => true,
    recurse => true,
    force   => true,
  }

  $groups.each |$group| {
    file { "/etc/manila/groups/$group":
      ensure  => 'file',
      owner   => 'manila',
      group   => $group,
      content => '',
      require => [
        Package['ceph'],
      ],
    }
  }

  file { $::os_docker::manila::params::managed_dirs:
    ensure => directory,
    owner  => 'manila',
    group  => 'manila',
    mode   => '0755',
    before => Anchor['manila::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'manila-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/manila-manage':
    command => '/usr/bin/manila-manage',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    env     => $os_docker::manila::params::environment,
    volumes => $os_docker::manila::params::volumes,
    tag     => ['manila-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['manila::install::begin']
  -> Package<| tag == 'manila-package' |>
  -> Docker::Image<| tag == 'manila-docker' |>
  -> Docker::Command<| tag == 'manila-docker' |>
  ~> Anchor['manila::install::end']

  Anchor['manila::service::begin']
  ~> Docker::Run<| tag == 'manila-docker' |>
  ~> Anchor['manila::service::end']

  Docker::Run<| tag == 'manila-docker' |>
  -> Service<| tag == 'manila-service' |>

  os_docker::config_files { 'manila':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The manila user isn't a docker user and this runs as the manila user inside the
  # container anyway.
  Exec<| title == 'manila-manage db_sync' |> {
    user => 'root',
  }
}
