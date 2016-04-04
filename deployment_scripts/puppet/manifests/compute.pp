$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')
$firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
$private_net = $quantum_settings['default_private_net']
$roles = hiera('roles')

if ( $mlnx['network_type'] == 'ethernet' and $mlnx['iser'] ){
  $exclude_vf = '0'
} else {
  $exclude_vf = ''
}

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::compute_sriov' :
    physnet             => $quantum_settings['predefined_networks'][$private_net]['L2']['physnet'],
    physifc             => $mlnx['physical_port'],
    mlnx_driver         => $mlnx['driver'],
    network_type        => $mlnx['network_type'],
    firewall_driver     => $firewall_driver,
    exclude_vf          => $exclude_vf,
  }
}

# Configure QoS for ConnectX3 ETH
if ( $mlnx['driver'] == 'mlx4_en' and $mlnx['mlnx_qos'] ) {
  class { 'mellanox_openstack::configure_qos' :
    mlnx_sriov => $mlnx['sriov'],
    roles      => $roles
  }
}
