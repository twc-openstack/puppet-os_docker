class os_docker::designate::common {
  include ::designate::params

  $managed_dirs = [
    '/etc/designate/rootwrap.d',
    $::designate::params::log_dir,
  ]
  file { $managed_dirs:
    ensure => directory,
    owner  => 'designate',
    group  => 'designate',
    mode   => '0750',
    before => Anchor['designate::install::begin'],
  }
}
