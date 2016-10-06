class os_docker::swift::params {

  $config_files = {
    '/etc/swift/proxy-server.conf' => { replace => false },
  }

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/swift/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/swift',
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
    '/etc/swift:/etc/swift:ro',
    '/var/run/swift:/var/run/swift',
    '/srv/node:/srv/node',
    '/var/cache/swift:/var/cache/swift',
    '/var/lock:/var/lock',
    '/dev:/dev:ro',
  ]
}
