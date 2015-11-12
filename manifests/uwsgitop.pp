# == Class: os_docker::uwsgitop
#
# This class handles any docker related changes needed for this service.
# Currently this includes creating the docker container and the startup script
# to go with it.
#
# === Parameters
#
# [*service_name*] (optional) Name of the service to create the uwsgitop
# wrapper for.  Default: $name
#
# [*socket_path*] (required) Path to the stats socket to use with uwsgitop
#
# [*log_dir*] (required) Path to the log directory for the service.  This will
# be mounted in the container.
#
# [*image_name*] (required) The name of the docker image to use for the
# uwsgitop container.
#
# [*image_tag*] (required) The tag of the docker image to use for the
# uwsgitop container.
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Command resource.  Default: none
#
#
define os_docker::uwsgitop(
  $socket_path,
  $log_dir,
  $image_name,
  $image_tag,
  $service_name = $name,
  $run_override = {},
){
  $default_params = {
    command     => "/usr/bin/uwsgitop ${socket_path}",
    image       => "${image_name}:${image_tag}",
    net         => 'host',
    interactive => true,
    tty         => true,
    volumes     => [
      "${log_dir}:${log_dir}",
      "${socket_path}:${socket_path}",
    ],
  }

  $uwsgitop_resource = merge($default_params, $run_override)
  create_resources('::docker::command',
    { "/usr/bin/${service_name}-uwsgitop" => $uwsgitop_resource }
  )
}
