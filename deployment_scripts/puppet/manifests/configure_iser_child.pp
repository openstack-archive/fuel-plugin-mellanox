$mlnx = hiera('mellanox-plugin')
$network_scheme = hiera('network_scheme')

if $mlnx['iser'] and $mlnx['driver'] == 'eth_ipoib' and $mlnx['storage_pkey'] {
  $iser_parent=$mlnx['iser_ifc_name']
  $iser_pkey=$mlnx['storage_pkey']
  $iser_child="${iser_parent}.${iser_pkey}"
  $iser_ipaddr=$network_scheme['endpoints'][$iser_parent]['IP']

  class { 'mellanox_openstack::iser_child':
    storage_parent    => $mlnx['iser_ifc_name'],
    iser_pkey         => $mlnx['storage_pkey'],
  }

  class { 'mellanox_openstack::configure_iser_child':
    iser_parent      => $iser_parent,
    iser_child       => $iser_child,
    iser_ipaddr      => $iser_ipaddr
  }

  Class['mellanox_openstack::iser_child'] ~>
  Class['mellanox_openstack::configure_iser_child']
}
