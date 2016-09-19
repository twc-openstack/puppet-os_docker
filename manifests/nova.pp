# == Class: os_docker::nova
#
# This class adds docker support to the nova puppet module.  It supports
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
# nova services.  This can overridden on a per service basis. This image will
# be used for the nova-manage script.
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
# /etc/nova. Default: $::os_docker::nova::params::config_files
#
class os_docker::nova(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::nova::params::config_files,
) inherits os_docker::nova::params {

  file { $::os_docker::nova::params::managed_dirs:
    ensure => directory,
    owner  => 'nova',
    group  => 'nova',
    mode   => '0755',
    before => Anchor['nova::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'nova-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/nova-manage':
    command => '/usr/bin/nova-manage',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    volumes => [
      '/etc/nova:/etc/nova:ro',
      '/var/log/nova:/var/log/nova',
    ],
    tag     => ['nova-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['nova::install::begin']
  -> Package<| tag == 'nova-package' |>
  -> Docker::Image<| tag == 'nova-docker' |>
  -> Docker::Command<| tag == 'nova-docker' |>
  ~> Anchor['nova::install::end']

  Anchor['nova::service::begin']
  ~> Docker::Run<| tag == 'nova-docker' |>
  ~> Anchor['nova::service::end']

  Docker::Run<| tag == 'nova-docker' |>
  -> Service<| tag == 'nova-service' |>

  os_docker::config_files { 'nova':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The nova user isn't a docker user and this runs as the nova user inside the
  # container anyway.
  Exec<| title == 'nova-dbsync' |> {
    user => 'root',
  }
}
