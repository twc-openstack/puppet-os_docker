# == Class: os_docker::swift
#
# This class adds docker support to the swift puppet module.  It supports
# pulling multiple docker images and switching between them by rewriting the
# init scripts and shell wrappers and then restarting the services.  It's
# expected that the images in use will be configured via hiera and that
# switching between active images will be done in the same way, but nothing
# prevents static configuration either.
#
# === Parameters
#
# [*active_image_name*] (required) Name of the image to use by default for all
# swift services.  This can overridden on a per service basis. This image will
# be used for the swift-init script.
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
# /etc/swift.  For virtualenv installs example config files can be copied from
# the module, or provided by the user.  Default:
# $::os_docker::nova::params::config_files
#
class os_docker::swift(
  $active_image_name,
  $active_image_tag  = 'latest',
  $active_image_overrides = {},
  $release_name,
  $extra_images           = {},
  $config_files     = $::os_docker::swift::params::config_files,
) inherits os_docker::swift::params {

  file { $::os_docker::swift::params::managed_dirs:
    ensure => directory,
    owner  => 'swift',
    group  => 'swift',
    mode   => '0755',
    before => Anchor['swift::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'swift-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

    file { '/etc/swift/groups':
      ensure  => 'directory',
      owner   => 'swift',
      group   => 'swift',
      mode    => '0755',
      purge   => true,
      recurse => true,
      force   => true,
    }

    file { '/etc/swift/groups/swift':
      ensure  => 'file',
      owner   => 'swift',
      group   => 'swift',
      mode    => '0755',
      require => User['swift'],
    }


#  docker::command { '/usr/bin/swift-init':
#    command => '/usr/bin/swift-init',
#    image   => "${active_image_name}:${active_image_tag}",
#    net     => 'host',
#    volumes => [
#      '/etc/swift:/etc/swift:ro',
#      '/var/log/swift:/var/log/swift',
#    ],
#    tag     => ['swift-docker'],
#  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['swift::install::begin']
  -> Package<| tag == 'swift-package' |>
  -> Docker::Image<| tag == 'swift-docker' |>
  -> Docker::Command<| tag == 'swift-docker' |>
  ~> Anchor['swift::install::end']

  Anchor['swift::service::begin']
  ~> Docker::Run<| tag == 'swift-docker' |>
  ~> Anchor['swift::service::end']

  Docker::Run<| tag == 'swift-docker' |>
  -> Service<| tag == 'swift-service' |>

#  os_docker::config_files { 'nova':
#    release_name => $release_name,
#    config_files => $config_files,
#    image_name   => $active_image_name,
#    image_tag    => $active_image_tag,
#  }

  # The nova user isn't a docker user and this runs as the nova user inside the
  # container anyway.
#  Exec<| title == 'nova-dbsync' |> {
#    user => 'root',
#  }
}
