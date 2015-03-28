$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')

class { 'mellanox_openstack::compute' :
  physnet => $quantum_settings['predefined_networks']['net04']['L2']['physnet'],
  physifc => $mlnx['physical_port'],
}
