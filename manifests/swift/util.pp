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
# [*environment*] (optional) list of "-e" paramaters passed into the
# container.  Used to set user name:group in the container. Not passing
# in any args will start container as root.
#
define os_docker::swift::util(
  $active_image_name = $::os_docker::swift::active_image_name,
  $active_image_tag  = $::os_docker::swift::active_image_tag,
  $environment       = undef,
){

  os_docker::command { "/usr/bin/${title}":
    command          => "/usr/bin/${title}",
    image            => "${active_image_name}:${active_image_tag}",
    net              => 'host',
    env              => $environment,
    privileged       => false,
    rm               => true,
    detach           => false,
    extra_parameters => ["--name=${title}"],
    volumes          => $::os_docker::swift::params::volumes,
    tag              => ['swift-docker'],
  }

}
