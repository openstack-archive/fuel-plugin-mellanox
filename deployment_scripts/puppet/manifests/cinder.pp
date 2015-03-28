$mlnx = hiera('mellanox-plugin')
$storage_address = hiera('storage_address')

class { 'mellanox_openstack::cinder' :
  iser            => $mlnx['iser'],
  iser_ip_address => $storage_address,
}
