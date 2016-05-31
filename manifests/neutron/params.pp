class os_docker::neutron::params {
  include ::neutron::params

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
    '/etc/neutron/api-paste.ini'                          => { replace => false },
    '/etc/neutron/dhcp_agent.ini'                         => { replace => false },
    '/etc/neutron/l3_agent.ini'                           => { replace => false },
    '/etc/neutron/metadata_agent.ini'                     => { replace => false },
    '/etc/neutron/metering_agent.ini'                     => { replace => false },
    '/etc/neutron/neutron.conf'                           => { replace => false },
    '/etc/neutron/plugins/ml2/linuxbridge_agent.ini'      => { replace => false },
    '/etc/neutron/plugins/ml2/ml2_conf_brocade_fi_ni.ini' => { replace => false },
    '/etc/neutron/plugins/ml2/ml2_conf_brocade.ini'       => { replace => false },
    '/etc/neutron/plugins/ml2/ml2_conf_fslsdn.ini'        => { replace => false },
    '/etc/neutron/plugins/ml2/ml2_conf.ini'               => { replace => false },
    '/etc/neutron/plugins/ml2/ml2_conf_ofa.ini'           => { replace => false },
    '/etc/neutron/plugins/ml2/ml2_conf_sriov.ini'         => { replace => false },
    '/etc/neutron/plugins/ml2/openvswitch_agent.ini'      => { replace => false },
    '/etc/neutron/plugins/ml2/sriov_agent.ini'            => { replace => false },
    '/etc/neutron/policy.json'                            => { replace => false },
    '/etc/neutron/rootwrap.conf'                          => { replace => true },
    '/etc/neutron/rootwrap.d/debug.filters'               => { replace => true },
    '/etc/neutron/rootwrap.d/dhcp.filters'                => { replace => true },
    '/etc/neutron/rootwrap.d/dibbler.filters'             => { replace => true },
    '/etc/neutron/rootwrap.d/ebtables.filters'            => { replace => true },
    '/etc/neutron/rootwrap.d/ipset-firewall.filters'      => { replace => true },
    '/etc/neutron/rootwrap.d/iptables-firewall.filters'   => { replace => true },
    '/etc/neutron/rootwrap.d/l3.filters'                  => { replace => true },
    '/etc/neutron/rootwrap.d/linuxbridge-plugin.filters'  => { replace => true },
    '/etc/neutron/rootwrap.d/openvswitch-plugin.filters'  => { replace => true },
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
