$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')
$firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
$exclude_vf = '0'

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::compute_sriov' :
    physnet             => $quantum_settings['predefined_networks']['net04']['L2']['physnet'],
    physifc             => $mlnx['physical_port'],
    mlnx_driver         => $mlnx['driver'],
    firewall_driver     => $firewall_driver,
    exclude_vf          => $exclude_vf, 
  }
}

