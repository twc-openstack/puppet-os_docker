class os_docker::glance::params {
  include ::glance::params

  $managed_dirs = [
    '/etc/neutron',
    '/etc/neutron/plugins',
    '/etc/neutron/plugins/ml2',
    '/etc/neutron/rootwrap.d',
    '/var/lib/neutron',
    '/var/lock/neutron',
    '/var/log/neutron',
  ]

  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However with docker, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the os_docker::glance class.
  $config_files  = {
    'api-paste.ini'                          => { replace => true },
    'dhcp_agent.ini'                         => { replace => true },
    'l3_agent.ini'                           => { replace => true },
    'metadata_agent.ini'                     => { replace => true },
    'metering_agent.ini'                     => { replace => true },
    'neutron.conf'                           => { replace => true },
    'plugins/ml2/linuxbridge_agent.ini'      => { replace => true },
    'plugins/ml2/ml2_conf_brocade_fi_ni.ini' => { replace => false },
    'plugins/ml2/ml2_conf_brocade.ini'       => { replace => false },
    'plugins/ml2/ml2_conf_fslsdn.ini'        => { replace => false },
    'plugins/ml2/ml2_conf.ini'               => { replace => true },
    'plugins/ml2/ml2_conf_ofa.ini'           => { replace => false },
    'plugins/ml2/ml2_conf_sriov.ini'         => { replace => false },
    'plugins/ml2/openvswitch_agent.ini'      => { replace => true },
    'plugins/ml2/sriov_agent.ini'            => { replace => false },
    'policy.json'                            => { replace => false },
    'rootwrap.conf'                          => { replace => false },
    'rootwrap.d/debug.filters'               => { replace => false },
    'rootwrap.d/dhcp.filters'                => { replace => false },
    'rootwrap.d/dibbler.filters'             => { replace => false },
    'rootwrap.d/ebtables.filters'            => { replace => false },
    'rootwrap.d/ipset-firewall.filters'      => { replace => false },
    'rootwrap.d/iptables-firewall.filters'   => { replace => false },
    'rootwrap.d/l3.filters'                  => { replace => false },
    'rootwrap.d/linuxbridge-plugin.filters'  => { replace => false },
    'rootwrap.d/openvswitch-plugin.filters'  => { replace => false },
  }

  $volumes = [
    '/run/openvswitch:/run/openvswitch',
    '/lib/modules:/lib/modules:ro',
    '/etc/neutron:/etc/neutron:ro',
    '/var/log/neutron:/var/log/neutron',
    '/var/lib/neutron:/var/lib/neutron',
    '/run/lock/neutron:/run/lock/neutron',
    '/run/neutron:/run/neutron',
  ]
}
