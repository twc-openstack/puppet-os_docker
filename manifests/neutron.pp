# == Class: os_docker::neutron
#
# This class adds docker support to the neutron puppet module.  It supports
# pulling multiple docker images and switching between them by rewriting the
# init scripts and shell wrappers and then restarting the services.  It's
# expected that the images in use will be configured via hiera and that
# switching between active images will be done in the same way, but nothing
# prevents static configuration either.
#
# === Parameters
#
# [*active_image_name*] (required) Name of the image to use by default for all
# neutron services.  This can overridden on a per service basis. This image will
# be used for the neutron-manage script.
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
# /etc/neutron.  For virtualenv installs example config files can be copied from
# the module, or provided by the user.  Default:
# $::os_docker::neutron::params::config_files
#
# [*groups*] (optional) Groups that the neutron user inside the container should
# be a member of.
#
class os_docker::neutron(
  $active_image_name,
  $active_image_tag  = 'latest',
  $active_image_overrides = {},
  $release_name,
  $extra_images = {},
  $config_files = $::os_docker::neutron::params::config_files,
  $groups = [],
) inherits os_docker::neutron::params {

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/neutron/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/neutron',
  ]

  # This directory exists to hold files the neutron user needs to be able to
  # read.  The container is expected to ensure the neutron user inside the
  # container is a member of the groups that own the files in the directory.
  file { '/etc/neutron/groups':
    ensure  => 'directory',
    owner   => 'neutron',
    group   => 'neutron',
    mode    => '0755',
    purge   => true,
    recurse => true,
    force   => true,
  }

  $groups.each |$group| {
    file { "/etc/neutron/groups/$group":
      ensure  => 'file',
      owner   => 'neutron',
      group   => $group,
      content => '',
      require => [
        Package['ceph'],
      ],
    }
  }

  file { $::os_docker::neutron::params::managed_dirs:
    ensure => directory,
    owner  => 'neutron',
    group  => 'neutron',
    mode   => '0755',
    before => Anchor['neutron::install::begin'],
  }
  $active_image = { "${active_image_name}:${active_image_tag}" => {
    image     => $active_image_name,
    image_tag => $active_image_tag,
  } }

  $image_defaults = { 'tag' => [ 'neutron-docker' ] }
  $active_image_defaults = merge($image_defaults, $active_image_overrides)
  create_resources('::docker::image', $active_image, $active_image_defaults)
  create_resources('::docker::image', $extra_images, $image_defaults)

  $commands = [
    'neutron-db-manage',
    'neutron-debug',
    'neutron-ipset-cleanup',
    'neutron-netns-cleanup',
    'neutron-ovs-cleanup',
    'neutron-sanity-check',

  ]
  $commands.each |$command| {
    docker::command { "/usr/bin/${command}":
      command => "/usr/bin/${command}",
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => $::os_docker::neutron::params::volumes,
      tag     => ['neutron-docker'],
    }
  }

  # We want to make sure any packages are ensured absent before putting
  # replacements in place
  Anchor['neutron::install::begin']
  -> Package<| tag == 'neutron-package' |>
  -> Docker::Image<| tag == 'neutron-docker' |>
  -> Docker::Command<| tag == 'neutron-docker' |>
  ~> Anchor['neutron::install::end']

  Anchor['neutron::service::begin']
  ~> Docker::Run<| tag == 'neutron-docker' |>
  ~> Anchor['neutron::service::end']

  Docker::Run<| tag == 'neutron-docker' |>
  -> Service<| tag == 'neutron-service' |>

  os_docker::config_files { 'neutron':
    release_name => $release_name,
    config_files => $config_files,
    image_name   => $active_image_name,
    image_tag    => $active_image_tag,
  }

  # The neutron user isn't a docker user and this runs as the neutron user inside the
  # container anyway.
  Exec<| title == 'neutron-db-sync' |> {
    user => 'root',
  }
}
