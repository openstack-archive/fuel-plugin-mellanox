$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')
$firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
$private_net = $quantum_settings['default_private_net']

if ( $mlnx_driver == 'mlx4_en' ){
  $exclude_vf = '0'
} else {
  $exclude_vf = ''
}

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::compute_sriov' :
    physnet             => $quantum_settings['predefined_networks'][$private_net]['L2']['physnet'],
    physifc             => $mlnx['physical_port'],
    mlnx_driver         => $mlnx['driver'],
    firewall_driver     => $firewall_driver,
    exclude_vf          => $exclude_vf,
  }
}
