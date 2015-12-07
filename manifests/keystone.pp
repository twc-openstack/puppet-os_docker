# == Class: os_docker::keystone
#
# This class adds docker support to the keystone puppet module.  It supports
# pulling multiple docker images and switching between them by rewriting the
# init scripts and shell wrappers and then restarting the services.  It's
# expected that the images in use will be configured via hiera and that
# switching between active images will be done in the same way, but nothing
# prevents static configuration either.
#
# === Parameters
#
# [*active_image_name*] (required) Name of the image to use by default for all
# keystone services.  This can overridden on a per service basis. This image will
# be used for the keystone-manage script.
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
# /etc/keystone.  For virtualenv installs example config files can be copied from
# the module, or provided by the user.  Default:
# $::os_docker::keystone::params::config_files
#
class os_docker::keystone(
  $active_image_name,
  $active_image_tag  = 'latest',
  $active_image_overrides = {},
  $release_name,
  $extra_images           = {},
  $config_files     = $::os_docker::keystone::params::config_files,
) inherits os_docker::keystone::params {

  file { $::os_docker::keystone::params::managed_dirs:
    ensure => directory,
    owner  => 'keystone',
    group  => 'keystone',
    mode   => '0750',
    before => Anchor['keystone::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'keystone-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/keystone-manage':
    command => '/usr/bin/keystone-manage',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    volumes => [
      '/etc/keystone:/etc/keystone:ro',
      '/etc/keystone/fernet-keys:/etc/keystone/fernet-keys',
      '/var/log/keystone:/var/log/keystone',
    ],
    tag     => ['keystone-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['keystone::install::begin']
  -> Package<| tag == 'keystone-package' |>
  -> Docker::Image<| tag == 'keystone-docker' |>
  -> Docker::Command<| tag == 'keystone-docker' |>
  ~> Anchor['keystone::install::end']

  Anchor['keystone::service::begin']
  ~> Docker::Run<| tag == 'keystone-docker' |>
  ~> Anchor['keystone::service::end']

  os_docker::config_files { 'keystone':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The keystone user isn't a docker user and this runs as the keystone user inside the
  # container anyway.
  Exec<| title == 'keystone-dbsync' |> {
    user => 'root',
  }
}
