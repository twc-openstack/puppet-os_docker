# == Define: designate::startup_script
#
# Install system startup script for provided service.  By default this class
# will only install startup scripts if you're using virtualenvs.
#
# === Parameters
#
# [*ensure*]
#  (optional) The desired start of the startup script.  Defaults to 'auto',
#  which means that if we're using virtualenvs on a supported operating system,
#  then the script will be installed.  If $ensure is 'present', then the
#  startup will always be installed and will give an error if on an unsupported
#  operating system.  If $ensure is set to 'absent', then any startup scripts
#  with a matching name will be removed.  If $ensure is set to 'unmanaged', the
#  nothing will be done.
#
# [*source*]
#  (optional) file:// or puppet:// URL specifying the source to copy the
#  startup script from.  Defaults to module internal script.
#
define designate_ext::virtualenv::startup_script(
  $ensure = 'present',
  $source = undef,
) {
  validate_string($ensure)
  $valid_values = [
    '^present$',
    '^absent$',
  ]
  validate_re($ensure, $valid_values,
    "Unknown value '${ensure}' for ensure, must be present, absent, auto, or unmanaged")

  $ensure_real = $ensure ? {
    'present' => 'file',
    'absent'  => 'absent',
  }

  $module_source  = "puppet:///modules/designate_ext/startup/${name}.conf.upstart"
  file { "/etc/init/${name}.conf":
    ensure => $ensure_real,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => pick($source, $module_source),
  }
}
