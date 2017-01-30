class os_docker::keystone::params {
  include ::keystone::params

  $managed_dirs = [
    '/var/log/keystone',
    '/etc/keystone',
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

  $default_volumes = [
    '/etc/keystone:/etc/keystone:ro',
    # Keystone has a bug that requires it to have write access to the
    # fernet directory even though it will never write to it.
    '/etc/keystone/fernet-keys:/etc/keystone/fernet-keys',
    '/var/log/keystone:/var/log/keystone',
    # Keystone needs the certs mounted in order to use LDAPS
    '/etc/ssl/certs:/etc/ssl/certs:ro',
  ]

  if $::os_docker::keystone::enable_ssl {
    $ssl_volumes = [
      # Keystone needs certs mounted to start SSL endpoint(s)
      '/etc/keystone/ssl:/etc/keystone/ssl:ro',
      '/etc/keystone/ssl/certs:/etc/keystone/ssl/certs:ro',
      '/etc/keystone/ssl/private:/etc/keystone/ssl/private:ro',
    ]
    $volumes = concat($default_volumes, $ssl_volumes)
  } else {
    $volumes = $default_volumes
  }
}
