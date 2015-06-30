# == Define: designate::config_file
#
# Manage permissions for configuration files, and optionally create them if
# needed.  It also has the ability to automatically create symlinks to the
# managed config files from a virtualenv's directory.
#
# === Parameters
#
# [*file*]
#  (optional) The name of the file to manage.  The directory should not be
#  specified, since it will be assumed to be relative to /etc/designate.
#
# [*ensure*]
#  (optional) This is passed through to the file resource for the config file.
#  It can be undef, present, or absent.  Defaults to undef
#
# [*source_dir*]
#  (optional) Directory to copy config files from.  This should be a URL they
#  can be handled by Puppet's file resource.  It will attempt to append $file
#  and $file.sample to this path to find the file to copy.  One use for this is
#  to copy example config files from virtualenv git repos, but it can be used
#  to copy config files from anywhere.  Defaults to undef.
#
# [*link_from_dir*]
#  (optional) If specified, then link the config file given into the directory
#  given.  This is used to link the config files in /etc/designate into a
#  virtualenv environment.  Defines to undef.
#
# [*replace*]
#  (optional) If true, then files in source_dir will replace any config files
#  in /etc/designate when they change.  If false, then existing files will be
#  unmodified.  Defaults to false.
#
define designate_ext::config_file(
  $file          = $name,
  $ensure        = file,
  $source_dir    = 'puppet:///modules/designate_ext/config',
  $link_from_dir = undef,
  $replace       = false,
) {
  if $source_dir {
    $source = ["${source_dir}/${file}", "${source_dir}/${file}.sample"]
  }
  file { "/etc/designate/${file}":
    ensure  => $ensure,
    owner   => 'designate',
    group   => 'designate',
    mode    => '0640',
    source  => $source,
    replace => $replace,
  }

  if $link_from_dir {
    file { "${link_from_dir}/${file}":
      ensure => 'link',
      force  => true,
      target => "/etc/designate/${file}",
    }
  }
}
