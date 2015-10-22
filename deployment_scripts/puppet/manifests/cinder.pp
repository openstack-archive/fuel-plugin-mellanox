prepare_network_config(hiera('network_scheme', {}))
$mlnx = hiera('mellanox-plugin')

if ($mlnx['iser']) {
  class { 'mellanox_openstack::cinder_iser' :
    iser_ip_address => get_network_role_property('cinder/iscsi', 'ipaddr'),
  }
}
