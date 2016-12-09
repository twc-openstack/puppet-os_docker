# == Class: os_docker::mistral
#
# This class adds docker support to the mistral puppet module.  It supports
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
# mistral services.  This can overridden on a per service basis. This image will
# be used for the mistral-manage script.
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
# /etc/mistral. Default: $::os_docker::mistral::params::config_files
#
# [*groups*] (optional) Groups that the mistral user inside the container should
# be a member of.
#
class os_docker::mistral(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::mistral::params::config_files,
) inherits os_docker::mistral::params {

  file { $::os_docker::mistral::params::managed_dirs:
    ensure => directory,
    owner  => 'mistral',
    group  => 'mistral',
    mode   => '0750',
    before => Anchor['mistral::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'mistral-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  $commands = [
    'mistral-db-manage',
    'mistral-db-populate',
  ]
  $commands.each |$command| {
    docker::command { "/usr/bin/${command}":
      command => "/usr/bin/${command}",
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => $::os_docker::mistral::params::volumes,
      tag     => ['mistral-docker'],
    }
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['mistral::install::begin']
  -> Package<| tag == 'mistral-package' |>
  -> Docker::Image<| tag == 'mistral-docker' |>
  -> Docker::Command<| tag == 'mistral-docker' |>
  ~> Anchor['mistral::install::end']

  Anchor['mistral::service::begin']
  ~> Docker::Run<| tag == 'mistral-docker' |>
  ~> Anchor['mistral::service::end']

  Docker::Run<| tag == 'mistral-docker' |>
  -> Service<| tag == 'mistral-service' |>

  os_docker::config_files { 'mistral':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The mistral user isn't a docker user and this runs as the mistral user inside the
  # container anyway.
  Exec<| title == 'mistral-db-sync' |> {
    user => 'root',
  }
  Exec<| title == 'mistral-db-populate' |> {
    user => 'root',
  }
}
