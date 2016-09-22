class os_docker::cinder::params {
  include ::cinder::params

  $managed_dirs = [
    '/etc/cinder',
    '/etc/cinder/rootwrap.d',
    '/var/lib/cinder',
    '/var/lock/cinder',
    '/var/log/cinder',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::cinder class.
  $config_files  = {
    '/etc/cinder/cinder.conf'                         => { replace => false },
    '/etc/cinder/api-paste.ini'                       => { replace => false },
    '/etc/cinder/policy.json'                         => { replace => true },
    '/etc/cinder/logging.conf'                        => { replace => true },
    '/etc/cinder/rootwrap.conf'                       => { replace => true },
    '/etc/cinder/rootwrap.d/volume.filters'     => { replace => true },
  }

  $volumes = [
    '/etc/cinder:/etc/cinder:ro',
    '/etc/ceph:/etc/ceph:ro',
    '/etc/cinder/groups:/etc/cinder/groups:ro',
    '/var/log/cinder:/var/log/cinder',
    '/var/lock/cinder:/var/lock/cinder',
    '/var/lib/cinder:/var/lib/cinder',
    '/var/run/cinder:/var/run/cinder',
    '/var/run/monasca:/var/run/monasca',
    '/var/lib/ceph:/var/lib/ceph',
    '/usr/lib/ceph:/usr/lib/ceph',
  ]

  $backup_volumes = [
   '/etc/cinder:/etc/cinder:ro',
   '/etc/ceph:/etc/ceph:ro',
   '/etc/cinder/groups:/etc/cinder/groups:ro',
   '/var/log/cinder:/var/log/cinder',
   '/var/lock/cinder:/var/lock/cinder',
   '/var/lib/cinder:/var/lib/cinder',
   '/var/run/cinder:/var/run/cinder',
  ]

}
