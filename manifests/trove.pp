# == Class: os_docker::trove
#
# This class adds docker support to the trove puppet module.  It supports
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
# trove services.  This can overridden on a per service basis. This image will
# be used for the trove-manage script.
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
# /etc/trove. Default: $::os_docker::trove::params::config_files
#
# [*groups*] (optional) Groups that the trove user inside the container should
# be a member of.
#
class os_docker::trove(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::trove::params::config_files,
) inherits os_docker::trove::params {

  file { $::os_docker::trove::params::managed_dirs:
    ensure => directory,
    owner  => 'trove',
    group  => 'trove',
    mode   => '0750',
    before => Anchor['trove::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'trove-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  $commands = [
    'trove-manage',
  ]
  $commands.each |$command| {
    docker::command { "/usr/bin/${command}":
      command => "/usr/bin/${command}",
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => $::os_docker::trove::params::volumes,
      tag     => ['trove-docker'],
    }
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['trove::install::begin']
  -> Package<| tag == 'trove-package' |>
  -> Docker::Image<| tag == 'trove-docker' |>
  -> Docker::Command<| tag == 'trove-docker' |>
  ~> Anchor['trove::install::end']

  Anchor['trove::service::begin']
  ~> Docker::Run<| tag == 'trove-docker' |>
  ~> Anchor['trove::service::end']

  Docker::Run<| tag == 'trove-docker' |>
  -> Service<| tag == 'trove-service' |>

  os_docker::config_files { 'tesora-trove':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The trove user isn't a docker user and this runs as the trove user inside the
  # container anyway.
  Exec<| title == 'trove-manage db_sync' |> {
    user => 'root',
  }
}
