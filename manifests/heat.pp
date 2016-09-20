# == Class: os_docker::heat
#
# This class adds docker support to the Heat puppet module.  It supports
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
# heat services.  This can overridden on a per service basis. This image will
# be used for the heat-manage script.
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
# /etc/heat. Default: $::os_docker::heat::params::config_files
#
class os_docker::heat(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::heat::params::config_files,
) inherits os_docker::heat::params {

  file { $::os_docker::heat::params::managed_dirs:
    ensure => directory,
    owner  => 'heat',
    group  => 'heat',
    mode   => '0750',
    before => Anchor['heat::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'heat-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/heat-manage':
    command => '/usr/bin/heat-manage',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    volumes => [
      '/etc/heat:/etc/heat:ro',
      '/var/log/heat:/var/log/heat',
    ],
    tag     => ['heat-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['heat::install::begin']
  -> Package<| tag == 'heat-package' |>
  -> Docker::Image<| tag == 'heat-docker' |>
  -> Docker::Command<| tag == 'heat-docker' |>
  ~> Anchor['heat::install::end']

  Anchor['heat::service::begin']
  ~> Docker::Run<| tag == 'heat-docker' |>
  ~> Anchor['heat::service::end']

  Docker::Run<| tag == 'heat-docker' |>
  -> Service<| tag == 'heat-service' |>

  os_docker::config_files { 'heat':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The heat user isn't a docker user and this runs as the heat user inside the
  # container anyway.
  Exec<| title == 'heat-dbsync' |> {
    user => 'root',
  }
}
