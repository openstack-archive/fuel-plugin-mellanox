$mlnx = hiera('mellanox-plugin')
$storage_address = hiera('storage_address')

if ($mlnx['iser']) {
  class { 'mellanox_openstack::cinder_iser' :
    iser_ip_address => $storage_address,
  }
}
