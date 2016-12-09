class os_docker::mistral::params {
  include ::mistral::params

  $managed_dirs = [
    '/etc/mistral',
    '/etc/mistral/conf.d',
    '/var/lib/mistral',
    '/var/log/mistral',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::mistral class.
  $config_files  = {
    '/etc/mistral/event_definitions.yml'     =>  { replace => false },
    '/etc/mistral/logging.conf'              =>  { replace => false },
    '/etc/mistral/logging.conf.rotating'     =>  { replace => false },
    '/etc/mistral/policy.json'               =>  { replace => false },
    '/etc/mistral/mistral.conf'              =>  { replace => false },
    '/etc/mistral/wf_trace_logging.conf'     =>  { replace => false },
    '/etc/mistral/wf_trace_logging.rotating' =>  { replace => false },
  }

  $volumes = [
    '/etc/mistral:/etc/mistral:ro',
    '/var/log/mistral:/var/log/mistral',
    '/var/lib/mistral:/var/lib/mistral',
  ]
}
