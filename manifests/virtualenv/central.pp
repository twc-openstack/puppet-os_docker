# == Class: designate_ext::virtualenv::central
#
# This class handles any virtualenv related changes needed for this service.
# Currently this includes setting up a startup script by default.
#
# === Parameters
#
# [*manage_startup_script*] (optional) Whether or not to manage the startup
# script for this service.  Default: true
#
# [*startup_script_source*] (optional) If specified, this should be a value
# that Puppet understands as a valid source for a file resource.  Default:
# startup script provided with the module.
#
class designate_ext::virtualenv::central(
  $manage_startup_script = true,
  $startup_script_source = undef,
){
  if $manage_startup_script {
    designate_ext::virtualenv::startup_script { 'designate-central':
      source => $startup_script_source,
    }
  }
}
