# == Class: designate_ext::virtualenv
#
# This module explicitly supports provisioning multiple virtualenv based
# installations in order to make upgrades and rollbacks easier.  To take
# advantage of this, you can define additional instances of
# designate_ext::virtualenv::instance type with the active flag set to false
# and with different $venv_prefix options.  The designate_ext class will allow
# configuring multiple virtualenvs via hiera.
#
# === Parameters
#
# [*virtualenvs*] Hash that will be passed to create_resources to create one or
# more virtualenvs.  This will be merged with $config_defaults to fill in any missing keys.
#
# [*config_defaults*] (optional) Hash that will be merged with each virtualenv
# to provide defaults across all virtualenvs
#
# [*basedir*] (optional) Base directory to store all of the virtualenvs under.
# Default: /var/lib/openstack-designate
#
# [*bindir_default*] (optional) directory to symlink binaries for the active
# virtualenv into.  Default: /usr/bin
#
# [*binaries_default*] (optional) Array of binaries to link from virtualenv
# directory to $bindir if the active virtualenv parameters don't provide it.
# Default: $::designate_ext::params::binaries
#
# [*config_files*] (optional) Hash of filenames and parameters to the
# designate_ext::config_file defined type.  Filenames should be relative to
# /etc/designate.  For virtualenv installs example config files can be copied
# from the module, or provided by the user.  Default:
# $::dessignate_ext::params::config_files
#
class designate_ext::virtualenv(
  $virtualenvs      = {},
  $config_defaults  = {},
  $basedir          = '/var/lib/openstack-designate',
  $bindir_default   = '/usr/bin',
  $binaries_default = $::designate_ext::params::binaries,
  $config_files     = $::designate_ext::params::config_files,
) inherits ::designate_ext::params {

  include ::designate_ext::common

  file { $basedir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  $internal_defaults = {
    basedir      => $basedir,
    bindir       => $bindir_default,
    binaries     => $binaries_default,
    config_files => $config_files,
  }

  $defaults_real = merge($internal_defaults, $config_defaults)
  create_resources('::designate_ext::virtualenv::instance', $virtualenvs, $defaults_real)
}
