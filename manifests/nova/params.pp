class os_docker::nova::params {
  include ::nova::params

  $managed_dirs = [
    '/etc/nova',
    '/etc/nova/rootwrap.d',
    '/var/log/nova',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::nova class.
  $config_files  = {
    '/etc/nova/nova.conf'                           => { replace => false },
    '/etc/nova/api-paste.ini'                       => { replace => false },
    '/etc/nova/logging.conf'                        => { replace => true },
    '/etc/nova/policy.json'                         => { replace => true },
    '/etc/nova/rootwrap.conf'                       => { replace => true },
    '/etc/nova/rootwrap.d/api-metadata.filters'     => { replace => true },
    '/etc/nova/rootwrap.d/compute.filters'          => { replace => true },
  }
}
