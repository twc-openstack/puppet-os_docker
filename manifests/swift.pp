# == Class: os_docker::swift
#
# This class adds docker support to the swift puppet module.  It is intended
# to be used with the "swift-init" service provider in the puppet-swift module
# and not systemd or init.  This module will lay down a wrapper to run
# swift-init within a container, which will start the specific swift service in
# that same container.  This container shares PID space with the host to be able
# to manage the swift services.  It's expected that the images in use will be
# configured via hiera and that switching between active images will be done in
# the same way, but nothing prevents static configuration either.
#
# === Parameters
#
# [*release_name*] (required) Openstack release name (kilo, liberty) associated
# with this image.  Used to populate default configuration files.
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
# [*extra_images*] (optional) Additional images associated with this service
# that should be pulled.  This is passed directly to Docker::Image.  This may
# be used to prepopulate new images.  Default: {}
#
# [*config_files*] (optional) Hash of filenames and parameters to the
# os_docker::config_file defined type.  Filenames should be relative to
# /etc/swift. Default: $::os_docker::nova::params::config_files
#
class os_docker::swift(
  $release_name,
  $active_image_name,
  $active_image_tag       = 'latest',
  $active_image_overrides = {},
  $extra_images           = {},
  $config_files           = $::os_docker::swift::params::config_files,
) {
  include os_docker::swift::params

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

  os_docker::command { '/usr/bin/swift-init':
    command          => '/usr/bin/swift-init --no-daemon',
    image            => "${active_image_name}:${active_image_tag}",
    net              => 'host',
    env              => $os_docker::swift::params::environment,
    privileged       => true,
    rm               => false,
    detach           => false,
    extra_parameters => ['--pid=host', '--name=swift-$1-$2'],
    volumes          => $os_docker::swift::params::volumes,
    template_name    => 'os_docker/docker/swift-init-command.erb',
    tag              => ['swift-docker'],
  }

  # Swift utilities that should run as root in the container.
  os_docker::swift::util { $::os_docker::swift::params::swift_user_utils:
    environment => $::os_docker::swift::params::environment,
  }
  # Swift utilities that should run as root in the container, the swift
  # environment is not passed into these so they run as root user not swift user.
  os_docker::swift::util { $::os_docker::swift::params::swift_root_utils: }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['swift::install::begin']
  -> Package<| tag == 'swift-package' |>
  -> Docker::Image<| tag == 'swift-docker' |>
  -> Os_docker::Command<| tag == 'swift-docker' |>
  ~> Anchor['swift::install::end']


  Os_docker::Command<| tag == 'swift-docker' |>
  -> Service<| tag == 'swift-service' |>

}
