class os_docker::ironic::params {
  include ::ironic::params

  $managed_dirs = [
    '/etc/ironic',
    '/var/lib/ironic',
    '/var/lock/ironic',
    '/var/log/ironic',
  ]

  $inspector_managed_dirs = [
    '/etc/ironic-inspector',
    '/etc/ironic-inspector/rootwrap.d',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::ironic class.
  $config_files  = {
    '/etc/ironic/ironic.conf'                                             => { replace => false },
  }

  $inspector_config_files  = {
    '/etc/ironic/ironic.conf'                                             => { replace => false },
    '/etc/ironic-inspector/inspector.conf'                                => { replace => false },
    '/etc/ironic-inspector/rootwrap.conf'                                 => { replace => true },
    '/etc/ironic-inspector/rootwrap.d/ironic-inspector-firewall.filters'  => { replace => true },
  }

}
