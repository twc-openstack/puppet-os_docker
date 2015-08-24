class os_docker::designate::params {
  $log_dir = '/var/log/designate'

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However for virtualenvs, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the main designate class.
  $config_files  = {
    'api-paste.ini'            => { replace => true  },
    'designate.conf'           => { replace => false },
    'policy.json'              => { replace => true  },
    'rootwrap.conf'            => { replace => true  },
    'rootwrap.d/bind9.filters' => { replace => true  },
  }

  # For virtualenv's we need to symlink the binaries a directory that is in the
  # path.  This is the default for the binaries to link and the place to link
  # them to.
  $binaries = [
    'designate-agent',
    'designate-api',
    'designate-central',
    'designate-manage',
    'designate-mdns',
    'designate-rootwrap',
    'designate-sink',
  ]
}
