# == Define: os_docker::swift::util
#
# This class creates a docker container wrapper for all of the
# supporting swift utilities.
#
# === Parameters
#
# [*title*] (required) Name of swift utility service wrapper to create
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::swift class.
#
define os_docker::swift::util(
  $active_image_name = $::os_docker::swift::active_image_name,
  $active_image_tag  = $::os_docker::swift::active_image_tag,
){

  os_docker::command { "/usr/bin/${title}":
    command          => "/usr/bin/${title}",
    image            => "${active_image_name}:${active_image_tag}",
    net              => 'host',
    env              => $os_docker::swift::params::environment,
    privileged       => false,
    rm               => true,
    detach           => false,
    extra_parameters => ["--name=${title}"],
    volumes          => $::os_docker::swift::params::volumes,
    tag              => ['swift-docker'],
  }

}
