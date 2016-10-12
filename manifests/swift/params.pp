class os_docker::swift::params {

  $config_files = {
    '/etc/swift/proxy-server.conf' => { replace => false },
  }

  $environment = [
    'OS_DOCKER_GROUP_DIR=/etc/swift/groups',
    'OS_DOCKER_HOME_DIR=/var/lib/swift',
  ]

  # Swift utilities that should run as the swift user in the container.
  $swift_user_utils = [
    'swift-config',
    'swift-form-signature',
    'swift-orphans',
    'swift-dispersion-populate',
    'swift-get-nodes',
    'swift-recon',
    'swift-temp-url',
    'swift-dispersion-report',
    'swift-recon-cron',
    'swift-drive-audit',
    'swift-oldies',
  ]

  # Swift utilities that should run as root in the container.
  $swift_root_utils = [
    'swift-ring-builder-analyzer',
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
