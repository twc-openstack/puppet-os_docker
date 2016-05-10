class os_docker::swift::params {
  include ::swift::params

  $managed_dirs = [
#    '/var/log/swift/',
#    '/etc/swift',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::keystone class.
  $config_files  = {
#    '/etc/keystone/default_catalog.templates'  => { replace => true },
#    '/etc/keystone/keystone.conf'              => { replace => false },
  }
}
