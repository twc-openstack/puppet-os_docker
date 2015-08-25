class os_docker::heat::params {
  include ::heat::params

  $managed_dirs = [
    '/etc/heat/environment.d',
    '/etc/heat/templates',
    '/var/log/heat',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::heat class.
  $config_files  = {
    '/etc/heat/environment.d/default.yaml'          => { replace => true },
    '/etc/heat/heat.conf'                           => { replace => false },
    '/etc/heat/api-paste.ini'                       => { replace => true },
    '/etc/heat/policy.json'                         => { replace => true },
    '/etc/heat/templates/AWS_CloudWatch_Alarm.yaml' => { replace => true },
    '/etc/heat/templates/AWS_RDS_DBInstance.yaml'   => { replace => true },
  }
}
