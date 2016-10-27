class os_docker::manila::params {
  include ::manila::params

  $managed_dirs = [
    '/etc/manila',
    '/etc/manila/rootwrap.d',
    '/var/lib/manila',
    '/var/lib/manila/mnt',
    '/var/lock/manila',
    '/var/log/manila',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::manila class.
  $config_files  = {
    '/etc/manila/manila.conf'              => { replace => true },
    '/etc/manila/api-paste.ini'            => { replace => false },
    '/etc/manila/policy.json'              => { replace => true },
    '/etc/manila/logging.conf'             => { replace => true },
    '/etc/manila/rootwrap.conf'            => { replace => true },
    '/etc/manila/rootwrap.d/share.filters' => { replace => true },
  }

  $volumes = [
    '/etc/manila:/etc/manila:ro',
    '/etc/ceph:/etc/ceph:ro',
    '/etc/manila/groups:/etc/manila/groups:ro',
    '/var/log/manila:/var/log/manila',
    '/var/lock/manila:/var/lock/manila',
    '/var/lib/manila:/var/lib/manila',
    '/var/run/manila:/var/run/manila',
    '/var/run/monasca:/var/run/monasca',
  ]

  $share_volumes = [
    '/etc/manila:/etc/manila:ro',
    '/etc/ceph:/etc/ceph:ro',
    '/etc/manila/groups:/etc/manila/groups:ro',
    '/var/log/manila:/var/log/manila',
    '/var/lock/manila:/var/lock/manila',
    '/var/lib/manila:/var/lib/manila',
    '/var/run/manila:/var/run/manila',
  ]

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/manila/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/manila',
  ]
}
