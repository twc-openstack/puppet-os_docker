# == Class: os_docker::keystone::all
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
# [*enable_uwsgitop*] (optional) If true, then create a command-wrapper that
# will invoke uwsgitop with the keystone-api uWSGI stats socket.
#
# [*run_override*] (optional) Hash of additional parameters to use when
# creating the Docker::Run resource.  Default: none
#
# [*active_image_name*] (optional) The name of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::keystone class.
#
# [*active_image_tag*] (optional) The tag of the docker image to use for the
# service container.  Defaults to the active container set via the main
# os_docker::keystone class.
#
class os_docker::keystone::all(
  $manage_service    = true,
  $enable_uwsgitop   = true,
  $run_override      = {},
  $active_image_name = $::os_docker::keystone::active_image_name,
  $active_image_tag  = $::os_docker::keystone::active_image_tag,
){
  include ::os_docker::keystone

  if $active_image_name {
    if $manage_service {
      $default_params = {
        image   => "${active_image_name}:${active_image_tag}",
        command => '/usr/bin/keystone',
        net     => 'host',
        volumes => [
          '/etc/keystone:/etc/keystone:ro',
          # Keystone has a bug that requires it to have write access to the
          # fernet directory even though it will never write to it.
          '/etc/keystone/fernet-keys:/etc/keystone/fernet-keys',
          '/var/log/keystone:/var/log/keystone',
          # Keystone needs the certs mounted in order to use LDAPS
          '/etc/ssl/certs:/etc/ssl/certs:ro',
          '/etc/monasca:/etc/monasca',
        ],
        tag => ['keystone-docker'],
        service_prefix => '',
        manage_service => false,
        extra_parameters => ['--restart=always'],
      }

      $all_resource = merge($default_params, $run_override)
      create_resources('::docker::run', { 'keystone' => $all_resource } )
    }

    docker::command { '/usr/bin/keystone-all':
      command => '/usr/bin/keystone-api',
      image   => "${active_image_name}:${active_image_tag}",
      net     => 'host',
      volumes => [
        '/etc/keystone:/etc/keystone:ro',
        # Keystone has a bug that requires it to have write access to the
        # fernet directory even though it will never write to it.
        '/etc/keystone/fernet-keys:/etc/keystone/fernet-keys',
        '/var/log/keystone:/var/log/keystone',
        '/etc/monasca:/etc/monasca',
      ],
      tag     => ['keystone-docker'],
    }

    if $enable_uwsgitop {
      ::os_docker::uwsgitop { 'keystone-main':
        socket_path => '/var/log/keystone/keystone-main.stats',
        log_dir     => '/var/log/keystone',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
      ::os_docker::uwsgitop { 'keystone-admin':
        socket_path => '/var/log/keystone/keystone-admin.stats',
        log_dir     => '/var/log/keystone',
        image_name  => $active_image_name,
        image_tag   => $active_image_tag,
      }
    }
  }
}
