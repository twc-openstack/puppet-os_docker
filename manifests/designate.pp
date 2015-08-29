# == Class: os_docker::designate
#
# This class adds docker support to the Designate puppet module.  It supports
# pulling multiple docker images and switching between them by rewriting the
# init scripts and shell wrappers and then restarting the services.  It's
# expected that the images in use will be configured via hiera and that
# switching between active images will be done in the same way, but nothing
# prevents static configuration either.
#
# === Parameters
#
# [*images*] Hash of docker image names and parameters that will be passed
# directly into docker::image.  However, it's recommended that these images be
# pulled via this class to ensure ordering of dependencies are managed
# properly.
#
# [*active_image_name*] (required) Name of the image to use by default for all
# designate services.  This can overridden on a per service basis.  This image
# will be used for the designate-manage script.
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
# /etc/designate.  For virtualenv installs example config files can be copied
# from the module, or provided by the user.  Default:
# $::os_docker::designate::params::config_files
#
class os_docker::designate(
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $release_name,
  $extra_images           = {},
  $config_files           = $::os_docker::designate::params::config_files,
) inherits os_docker::designate::params {

  file { $::os_docker::designate::params::managed_dirs:
    ensure => directory,
    owner  => 'designate',
    group  => 'designate',
    mode   => '0750',
    before => Anchor['designate::install::begin'],
  }

  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'designate-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  docker::command { '/usr/bin/designate-manage':
    command => '/usr/bin/designate-manage',
    image   => "${active_image_name}:${active_image_tag}",
    net     => 'host',
    volumes => [
      '/etc/designate:/etc/designate:ro',
      '/var/log/designate:/var/log/designate',
    ],
    tag     => ['designate-docker'],
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place.
  Anchor['designate::install::begin']
  -> Package<| tag == 'designate-package' |>
  -> Docker::Image<|   tag == 'designate-docker' |>
  -> Docker::Command<| tag == 'designate-docker' |>
  ~> Anchor['designate::install::end']

  Anchor['designate::service::begin']
  ~> Docker::Run<| tag == 'designate-docker' |>
  ~> Anchor['designate::service::end']

  class { '::os_docker::config_files':
    project_name => 'designate',
    release_name => $release_name,
  }
}
