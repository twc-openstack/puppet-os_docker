# == Define: designate_ext::virtualenv::instance
#
# This class will manage the installation of designate into a Python virtualenv.
# It will also manage the config files needed by that software, with different
# policies for packages and virtualenvs.  By default the config files will be
# copied from the template files internal to the module.  This behavior can be
# overridden by providing a $config_files hash.
#
# Virtualenv installations are built by installing packages from a given
# requirements.txt file. For production use you will normally want to override
# the requirements.txt and provide one that contains pinned module versions,
# and possibly include information about a local pypi mirror in the
# requirements.txt.
#
# This module explicitly supports provisioning multiple virtualenv based
# installations in order to make upgrades and rollbacks easier.  To take
# advantage of this, you can define additional instances of
# designate_ext::virtualenv::instance type with the active flag set to false
# and with different $venv_prefix options.  The designate_ext class will allow
# configuring multiple virtualenvs via hiera.
#
# If using virtualenv based installations it's *strongly* recommended that
# virtualenvs be treated as immutable once created.  Behavior with changing
# requirements.txt or code may not be what you expect, since the existing
# virtualenv will be updated, not rebuilt when requirements.txt or the git
# revision changes.
#
# === Parameters
#
# [*ensure*] (required) Whether or not the package should be removed or
# installed.  Should be 'present', or 'absent'. For package installs, other
# values such as a version number or 'latest' are also acceptable.
#
# [*venv_active*] (optional) Whether or not the virtualenv should be made
# active by managing symlinks into it and restarting services if the links are
# changed.  Only one virtualenv can be active at a time.  Defaults to false.
#
# [*basedir*] (required) Base directory for storing virtualenvs.
#
# [*bindir*] (required) Directory to link binaries into if the virtualenv is
# active.  Defaults to '/usr/bin'.
#
# [*binaries*] (required) Array of binaries to link from virtualenv directory
# to $bindir if the virtualenv is active.
#
# [*venv_prefix*] (required) Prefix to give to virtualenv directories
# This can be specified to provide more meaningful names, or to have multiple
# virtualenvs installed at the same time.
#
# [*venv_requirements*] (required) Python requirements.txt to pass to pip when
# populating the virtualenv.  Required if the instance is ensured to be present.
#
# [*venv_extra_args*] (optional) Extra arguments that will be passed to `pip
# install` when creating the virtualenv.
#
# [*config_files*] (required) Hash of filenames and parameters to the
# designate_ext::config_file defined type.  Filenames should be relative to
# /etc/designate.  For virtualenv installs example config files can be copied
# from the module, or provided by the user.

define designate_ext::virtualenv::instance(
  $basedir,
  $bindir,
  $binaries,
  $venv_prefix,
  $ensure            = 'present',
  $venv_requirements = undef,
  $venv_active       = false,
  $venv_extra_args   = undef,
  $config_files      = {},
) {
  validate_string($ensure)
  $valid_values = [
    '^present$',
    '^absent$',
  ]
  validate_re($ensure, $valid_values,
    "Unknown value '${ensure}' for ensure, must be present or absent")

  $req_dest = "${basedir}/${venv_prefix}-requirements.txt"
  $venv_dir = "${basedir}/${venv_prefix}-venv"
  $venv_name = "${venv_prefix}-${name}"

  if $ensure == 'present' {
    validate_string($venv_requirements)

    file { $req_dest:
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => $venv_requirements,
      before => Python::Virtualenv[$venv_name],
    }
  } else {
    file { $req_dest:
      ensure => 'absent',
    }
  }

  python::virtualenv { $venv_name:
    ensure         => $ensure,
    venv_dir       => $venv_dir,
    requirements   => $req_dest,
    extra_pip_args => $venv_extra_args,
    owner          => 'designate',
    group          => 'designate',
    require        => User['designate'],
    tag            => ['openstack'],
  }

  if $ensure == 'present' {
    file { ["${venv_dir}/etc", "${venv_dir}/etc/rootwrap.d"]:
      ensure => 'directory',
      owner  => 'designate',
      group  => 'designate',
      mode   => '0750',
    }
  }

  if $venv_active {
    $config_file_defaults = {
      link_from_dir => "${venv_dir}/etc",
    }
    create_resources(::designate_ext::config_file, $config_files, $config_file_defaults)
    # Creating the config directory and putting sample config files in place
    # should occur after the software is installed but before the main module
    # starts making it's changes to the config files.
    Anchor['designate::install::end']
    -> Designate_ext::Config_File<||>
    -> Anchor['designate::config::begin']

    designate_ext::virtualenv::binary_link { $binaries:
      source_dir => "${venv_dir}/bin",
      dest_dir   => $bindir,
      notify     => Anchor['designate::service::begin'],
    }

    # Only restart the services if we installed software in the active venv, or
    # changed the active venv.
    Python::Virtualenv[$venv_name] ~> Anchor['designate::service::begin']

    # Make sure the active virtualenv is created during install phase
    Anchor['designate::install::begin']
    -> Python::Virtualenv[$venv_name]
    ~> Anchor['designate::install::end']
  }
}
