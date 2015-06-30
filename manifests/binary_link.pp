# == Define:: designate::binary_link
#
# This will link the given file from the source directory into the binary
# directory.  This is used to link binaries from a virtualenv into a binary
# directory in the users path (such as /usr/bin).
#
# [*file*]
#  (optional) Name of the file (without the path) to link into the destination
#  directory.  Defaults to $name
#
# [*source_dir*]
#  (required) Directory to link from.  Should be the directory to link to,
#  usually a virtualenv's binary directory.
#
# [*dest_dir*]
#  (required) Directory to link to.  This should be a directory in the user's
#  path, usually /usr/bin.
#
define designate_ext::binary_link(
  $file       = $name,
  $source_dir = undef,
  $dest_dir   = undef,
) {
  file { "${dest_dir}/${file}":
    ensure => 'link',
    force  => true,
    target => "${source_dir}/${file}",
  }
}
