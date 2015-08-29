class os_docker::config_files(
  $project_name,
  $release_name,
) {
}
  $config_file_defaults = {
    config_dir => "/etc/${project_name}",
    owner      => ${project_name},
    group      => ${project_name},
    source_dir => "puppet:///modules/os_docker/${project_name}/config/${release_name}",
    tag        => "${project_name}-config-file",
  }
  create_resources(::os_docker::config_file, $config_files, $config_file_defaults)

  file { "/etc/${project_name}/release_name":
    ensure => 'file',
    owner  => $project_name,
    group  => $project_name,
    mode   => '0644',
    content => "${release_name}\n",
    tag     => "${project_name}-config-file",
  }

  # Creating the config directory and putting sample config files in place
  # should occur after the software is installed but before the main module
  # starts making it's changes to the config files.
  Anchor["${project_name}::install::end"]
  -> Os_docker::Config_File<| tag == "${project_name}-config-file" |>
  -> Anchor["${project_name}::config::begin"]
}
