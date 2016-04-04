$mlnx = hiera('mellanox-plugin')

if ($mlnx['iser'] and $mlnx['network_type'] == 'ethernet') {
  class { 'mellanox_openstack::iser_rename' :
    storage_parent      => $mlnx['storage_parent'],
    iser_interface_name => $mlnx['iser_ifc_name'],
  }
}
