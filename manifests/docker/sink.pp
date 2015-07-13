# == Class: designate_ext::docker::sink
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.
#
# === Parameters
#
# [*manage_service*] (optional) Whether or not to manage the docker container
# for this service.  Default: true
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# designate_ext::docker class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# designate_ext::docker class.
#
class designate_ext::docker::sink(
  $manage_service    = true,
  $run_override      = {},
  $active_image_name = $::designate_ext::docker::active_image_name,
  $active_image_tag  = $::designate_ext::docker::active_image_tag,
){
  include ::designate_ext::docker

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image   => "${active_image_name}:${active_image_tag}",
        command => '/usr/bin/designate-sink',
        net     => 'host',
        volumes => [
          '/etc/designate:/etc/designate:ro',
          '/var/log/designate:/var/log/designate',
        ],
        tag => ['designate-docker'],
        service_prefix => '',
        manage_service => false,
        extra_parameters => ['--restart=always'],
      }

      $sink_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'designate-sink' => $sink_resource } )
    }

    docker::command { '/usr/bin/designate-sink':
      command => '/usr/bin/designate-sink',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => [
        '/etc/designate:/etc/designate:ro',
        '/var/log/designate:/var/log/designate',
      ],
      tag     => ['designate-docker'],
    }
  }
}
