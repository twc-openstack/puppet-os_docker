# == Class: os_docker::ironic
#
# This class adds docker support to the ironic puppet module.  It supports
# pulling multiple docker images and switching between them by rewriting the
# init scripts and shell wrappers and then restarting the services.  It's
# expected that the images in use will be configured via hiera and that
# switching between active images will be done in the same way, but nothing
# prevents static configuration either.
#
# === Parameters
#
# [*active_image_name*] (required) Name of the image to use by default for all
# ironic services.  This can overridden on a per service basis. This image will
# be used for the ironic-manage script.
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
# /etc/ironic.  For virtualenv installs example config files can be copied from
# the module, or provided by the user.  Default:
# $::os_docker::ironic::params::config_files
#
class os_docker::ironic(
  $active_image_name,
  $active_image_tag  = 'latest',
  $active_image_overrides = {},
  $release_name,
  $extra_images           = {},
  $config_files     = $::os_docker::ironic::params::config_files,
) inherits os_docker::ironic::params {

  file { $::os_docker::ironic::params::managed_dirs:
    ensure => directory,
    owner  => 'ironic',
    group  => 'ironic',
    mode   => '0755',
    before => Anchor['ironic::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'ironic-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/ironic-dbsync':
    command => '/usr/bin/ironic-dbsync',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    volumes => [
      '/etc/ironic:/etc/ironic:ro',
      '/var/log/ironic:/var/log/ironic',
    ],
    tag     => ['ironic-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['ironic::install::begin']
  -> Package<| tag == 'ironic-package' |>
  -> Docker::Image<| tag == 'ironic-docker' |>
  -> Docker::Command<| tag == 'ironic-docker' |>
  ~> Anchor['ironic::install::end']

  Anchor['ironic::service::begin']
  ~> Docker::Run<| tag == 'ironic-docker' |>
  ~> Anchor['ironic::service::end']

  Docker::Run<| tag == 'ironic-docker' |>
  -> Service<| tag == 'ironic-service' |>

  os_docker::config_files { 'ironic':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The ironic user isn't a docker user and this runs as the ironic user inside the
  # container anyway.
  Exec<| title == 'ironic-dbsync' |> {
    user => 'root',
  }
}
