class os_docker::keystone::params {
  include ::keystone::params

  $managed_dirs = [
    '/var/log/keystone',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::keystone class.
  $config_files  = {
    '/etc/keystone/default_catalog.templates'  => { replace => true },
    '/etc/keystone/keystone.conf'              => { replace => false },
    '/etc/keystone/keystone-paste.ini'         => { replace => false },
    '/etc/keystone/logging.conf'               => { replace => true },
    '/etc/keystone/policy.json'                => { replace => true },
    '/etc/keystone/policy.v3cloudsample.json'  => { replace => true },
    '/etc/keystone/sso_callback_template.html' => { replace => true },
  }
}
