# == Defined Type: os_docker::config_files
#
# This defined type will manage all config files for a specific OpenStack
# project.  It will also handle replacing configuration files if the release of
# the project is changed.
#
# [*release_name*] (required) Openstack release name (kilo, liberty) associated
# with this image.  Used to populate default configuration files.
#
# [*config_files*] (required) Hash of filenames and parameters to the
# os_docker::config_file defined type.  Filenames should be relative to
# /etc/heat. Default: $::os_docker::heat::params::config_files
#
# [*image_name*] (required) Name of the Docker image being used for this
# project.  This is used to populate the version file that is read by the
# "${project_name}_version" fact.
#
# [*image_tag*] (required) Tag of the Docker image being used for this project.
# This is used to populate the version file that is read by the
# "${project_name}_version" fact.
#
# [*project_name*] (required) The name of the OpenStack project the config
# files are associated with.  This is used to set the base directory
# (/etc/<project_name>) and the owner of all of the configuration files.
#
define os_docker::config_files(
  $release_name,
  $config_files,
  $image_name,
  $image_tag,
  $project_name = $title,
) {
  $config_file_defaults = {
    config_dir => "/etc/${project_name}",
    owner      => $project_name,
    group      => $project_name,
    source_dir => "puppet:///modules/os_docker/${project_name}/config/${release_name}",
    tag        => "os_docker-${project_name}-config-file",
  }
  create_resources(::os_docker::config_file, $config_files, $config_file_defaults)

  # If we're upgrading, then replace all files
  if getvar("::${project_name}_release") != $release_name {
    Os_docker::Config_file<|tag == "os_docker-${project_name}-config-file"|> {
      replace => true,
   }
  }

  file { "/etc/${project_name}/release_name":
    ensure  => 'file',
    owner   => $project_name,
    group   => $project_name,
    mode    => '0644',
    content => "${release_name}\n",
    tag     => "os_docker-${project_name}-config-file",
  }

  file { "/etc/${project_name}/version":
    ensure  => 'file',
    owner   => $project_name,
    group   => $project_name,
    mode    => '0644',
    content => "${image_name}:${image_tag}\n",
    tag     => "os_docker-${project_name}-config-file",
  }


  # Creating the config directory and putting sample config files in place
  # should occur after the software is installed but before the main module
  # starts making it's changes to the config files.
  Anchor["${project_name}::install::end"]
  -> Os_docker::Config_File<| tag == "os_docker-${project_name}-config-file" |>
  -> Anchor["${project_name}::config::begin"]

  # If the config files are changed, the service should get restarted
  Os_docker::Config_File<| tag == "os_docker-${project_name}-config-file" |>
  ~> Anchor["${project_name}::service::begin"]

}
