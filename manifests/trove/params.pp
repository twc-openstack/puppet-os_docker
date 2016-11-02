class os_docker::trove::params {
  include ::trove::params

  $managed_dirs = [
    '/etc/trove',
    '/etc/trove/conf.d',
    '/var/lib/trove',
    '/var/log/trove',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::trove class.
  $config_files  = {
    '/etc/trove/api-paste.ini'          =>  { replace => false },
    '/etc/trove/policy.json'            =>  { replace => false },
    '/etc/trove/trove-conductor.conf'   =>  { replace => false },
    '/etc/trove/trove.conf'             =>  { replace => false },
    '/etc/trove/trove-guestagent.conf'  =>  { replace => false },
    '/etc/trove/trove-taskmanager.conf' =>  { replace => false },
    '/etc/trove/trove-workbook.yaml'    =>  { replace => false },
  }

  $volumes = [
    '/etc/trove:/etc/trove:ro',
    '/var/log/trove:/var/log/trove',
    '/var/lib/trove:/var/lib/trove',
  ]
}
