# == Class: designate_ext::docker
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
# [*active_image_name*] (optional) Name of the image to use by default for all
# designate services.  This can overridden on a per service basis.  If this is
# not specified then no image will be activated.  This means no shell wrappers
# and no init scripts will be created.
#
# [*active_image_tag*] (optional) Tag of the active_image_name to use.
# Default: 'latest'
#
# [*config_files*] (optional) Hash of filenames and parameters to the
# designate_ext::config_file defined type.  Filenames should be relative to
# /etc/designate.  For virtualenv installs example config files can be copied
# from the module, or provided by the user.  Default:
# $::designate_ext::params::config_files
#
class designate_ext::docker(
  $images            = {},
  $active_image_name = undef,
  $active_image_tag  = 'latest',
  $config_files     = $::designate_ext::params::config_files,
) inherits ::designate_ext::params {

  include ::designate_ext::common

  $image_defaults = { 'tag' => [ 'designate-docker' ] }
  create_resources('::docker::image', $images, $image_defaults)

  if $active_image_name {
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
  }

  Anchor['designate::install::begin']
  -> Docker::Image<|   tag == 'designate-docker' |>
  -> Docker::Command<| tag == 'designate-docker' |>
  ~> Anchor['designate::install::end']

  Anchor['designate::service::begin']
  ~> Docker::Run<| tag == 'designate-docker' |>
  ~> Anchor['designate::service::end']

  if $active_image_name {
    create_resources(::designate_ext::config_file, $config_files)
  }

  # Creating the config directory and putting sample config files in place
  # should occur after the software is installed but before the main module
  # starts making it's changes to the config files.
  Anchor['designate::install::end']
  -> Designate_ext::Config_File<||>
  -> Anchor['designate::config::begin']
}
