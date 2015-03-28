$mlnx = hiera('mellanox_plugin')

if ($mlnx['iser']) {
  class { 'mellanox_openstack::iser_rename' :
    storage_parent      => $mlnx['storage_parent'],
    iser_interface_name => $mlnx['iser_ifc_name'],
  }
}
