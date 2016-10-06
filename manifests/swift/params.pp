class os_docker::swift::params {

  $managed_dirs = [
  ]

  $swift_utils = [
    'swift-config',
    'swift-form-signature',
    'swift-orphans',
    'swift-ring-builder-analyzer',
    'swift-dispersion-populate',
    'swift-get-nodes',
    'swift-recon',
    'swift-temp-url',
    'swift-dispersion-report',
    'swift-recon-cron',
    'swift-drive-audit',
    'swift-oldies',
    'swift-ring-builder',
  ]

  $volumes = [
    '/run/openvswitch:/run/openvswitch',
    '/lib/modules:/lib/modules:ro',
    '/etc/neutron:/etc/neutron:ro',
    '/var/log/neutron:/var/log/neutron',
    '/var/lib/neutron:/var/lib/neutron',
    '/run/lock/neutron:/run/lock/neutron',
    '/run/neutron:/run/neutron',
  ]
}
