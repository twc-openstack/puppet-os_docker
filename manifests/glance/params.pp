class os_docker::glance::params {
  include ::glance::params

  $managed_dirs = [
    '/etc/glance',
    '/var/lib/glance',
    '/var/lock/glance',
    '/var/log/glance',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::glance class.
  $config_files  = {
    '/etc/glance/glance-api.conf'                           =>  { replace => false },
    '/etc/glance/glance-api-paste.ini'                      =>  { replace => false },
    '/etc/glance/glance-cache.conf'                         =>  { replace => false },
    '/etc/glance/glance-manage.conf'                        =>  { replace => false },
    '/etc/glance/glance-registry.conf'                      =>  { replace => false },
    '/etc/glance/glance-registry-paste.ini'                 =>  { replace => false },
    '/etc/glance/glance-scrubber.conf'                      =>  { replace => false },
    '/etc/glance/glance-swift.conf'                         =>  { replace => false },
    '/etc/glance/metadefs/compute-aggr-disk-filter.json'    =>  { replace => true },
    '/etc/glance/metadefs/compute-aggr-iops-filter.json'    =>  { replace => true },
    '/etc/glance/metadefs/compute-aggr-num-instances.json'  =>  { replace => true },
    '/etc/glance/metadefs/compute-cpu-pinning.json'         =>  { replace => true },
    '/etc/glance/metadefs/compute-guest-shutdown.json'      =>  { replace => true },
    '/etc/glance/metadefs/compute-host-capabilities.json'   =>  { replace => true },
    '/etc/glance/metadefs/compute-hypervisor.json'          =>  { replace => true },
    '/etc/glance/metadefs/compute-instance-data.json'       =>  { replace => true },
    '/etc/glance/metadefs/compute-libvirt-image.json'       =>  { replace => true },
    '/etc/glance/metadefs/compute-libvirt.json'             =>  { replace => true },
    '/etc/glance/metadefs/compute-quota.json'               =>  { replace => true },
    '/etc/glance/metadefs/compute-randomgen.json'           =>  { replace => true },
    '/etc/glance/metadefs/compute-trust.json'               =>  { replace => true },
    '/etc/glance/metadefs/compute-vcputopology.json'        =>  { replace => true },
    '/etc/glance/metadefs/compute-vmware-flavor.json'       =>  { replace => true },
    '/etc/glance/metadefs/compute-vmware.json'              =>  { replace => true },
    '/etc/glance/metadefs/compute-vmware-quota-flavor.json' =>  { replace => true },
    '/etc/glance/metadefs/compute-watchdog.json'            =>  { replace => true },
    '/etc/glance/metadefs/compute-xenapi.json'              =>  { replace => true },
    '/etc/glance/metadefs/glance-common-image-props.json'   =>  { replace => true },
    '/etc/glance/metadefs/operating-system.json'            =>  { replace => true },
    '/etc/glance/metadefs/software-databases.json'          =>  { replace => true },
    '/etc/glance/metadefs/software-runtimes.json'           =>  { replace => true },
    '/etc/glance/metadefs/software-webservers.json'         =>  { replace => true },
    '/etc/glance/policy.json'                               =>  { replace => true },
    '/etc/glance/property-protections-policies.conf'        =>  { replace => true },
    '/etc/glance/property-protections-roles.conf'           =>  { replace => true },
    '/etc/glance/schema-image.json'                         =>  { replace => true },
  }

  $volumes = [
    '/etc/glance:/etc/glance:ro',
    '/etc/ceph:/etc/ceph:ro',
    '/run/lock:/run/lock',
    '/var/log/glance:/var/log/glance',
    '/var/lib/glance:/var/lib/glance',
    '/var/run/glance:/var/run/glance',
  ]
}
