# == Define: os_docker::config_file
#
# Manage permissions for configuration files, and optionally create them if
# needed.  It also has the ability to automatically create symlinks to the
# managed config files from a virtualenv's directory.
#
# === Parameters
#
# [*path*]
#  (optional) This is the path to the config file to manage.  It should be the
#  complete path to the file since it must be unique across the entire catalog.
#  Default: $namevar
#
# [*config_dir*]
#  (required) Name of the base directory for all config files for the project.
#  It is expected that the project will set the default for this.
#
# [*owner*]
#  (required) Owner of the config file.  It is expected that the project will
#  set the default for this.
#
# [*group*]
#  (required) Group of the config file.  It is expected that the project will
#  set the default for this.
#
# [*mode*]
#  (required) Mode of the config file.  Defaults to "0640".
#
# [*source_dir*]
#  (required) Puppet URL to use as the base for all source parameters.  The
#  filename will be appended to this to find the file.  It is expected that the
#  project will set the default for this.
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
# [*replace*]
#  (optional) If true, then files in source_dir will replace any config files
#  in /etc/designate when they change.  If false, then existing files will be
#  unmodified.  Defaults to false.
#
define os_docker::config_file(
  $config_dir,
  $owner,
  $group,
  $source_dir,
  $path       = $name,
  $mode       = '0640',
  $ensure     = file,
  $replace    = false,
) {
 if $path =~ /^puppet:\/\// {
    $file = $name
    $path_real = $name
  } elsif $path =~ /^\// {
    $file = regsubst($path, "^${config_dir}/", '')
    $path_real = $path
  } else {
    $file = $path
    $path_real = "${config_dir}/${path}"
  }

  if $path =~ /^puppet:\/\// {
    $source = $path
  } elsif $source_dir {
    $source = ["${source_dir}/${file}", "${source_dir}/${file}.sample"]
  }

  file { $path_real:
    ensure  => $ensure,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    source  => $source,
    replace => $replace,
  }

}
