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
# [*active_image_name*] (required) Name of the image to use by default for all
# cinder services.  This can overridden on a per service basis. This image will
# be used for the cinder-manage script.
#
# [*active_image_tag*] (optional) Tag of the active_image_name to use.
# Default: 'latest'

# [*active_image_overrides*] (optional) Extra parameters to pass into
# Docker::Image when creating the active image resource.  Default: {}
#
# [*release_name*] (required) Openstack release name (kilo, liberty) associated
# with this image.  Used to populate default configuration files.
#
# [*extra_images*] (optional) Additional images associated with this service
# that should be pulled.  This is passed directly to Docker::Image.  This may
# be used to prepopulate new images.  Default: {}
#
# [*config_files*] (optional) Hash of filenames and parameters to the
# os_docker::config_file defined type.  Filenames should be relative to
# /etc/cinder.  For virtualenv installs example config files can be copied from
# the module, or provided by the user.  Default:
# $::os_docker::cinder::params::config_files
#
class os_docker::cinder(
  $active_image_name,
  $active_image_tag  = 'latest',
  $active_image_overrides = {},
  $release_name,
  $extra_images           = {},
  $config_files     = $::os_docker::cinder::params::config_files,
  $groups = ['cinder', 'ceph'],
) inherits os_docker::cinder::params {

  # This directory exists to hold files the cinder user needs to be able to
  # read.  The container is expected to ensure the cinder user inside the
  # container is a member of the groups that own the files in the directory.
  file { '/etc/cinder/groups':
    ensure  => 'directory',
    owner   => 'cinder',
    group   => 'cinder',
    mode    => '0755',
    purge   => true,
    recurse => true,
    force   => true,
  }

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/cinder/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/cinder',
  ]

  $groups.each |$group| {
    file { "/etc/cinder/groups/$group":
      ensure  => 'file',
      owner   => 'cinder',
      group   => $group,
      content => '',
      require => [
        Package['ceph'],
      ],
    }
  }

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
    env              => $environment,
    volumes => [
      '/etc/cinder:/etc/cinder:ro',
      '/var/log/cinder:/var/log/cinder',
      '/var/run/cinder:/var/run/cinder',
    ],
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
