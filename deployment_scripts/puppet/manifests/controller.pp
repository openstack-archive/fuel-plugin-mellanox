$mlnx = hiera('mellanox-plugin')
$eswitch_vnic_type = 'hostdev'
$eswitch_apply_profile_patch = 'True'
$mechanism_drivers = 'openvswitch'
$mlnx = hiera('mellanox-plugin')

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::controller_sriov' :
    eswitch_vnic_type           => $eswitch_vnic_type,
    eswitch_apply_profile_patch => $eswitch_apply_profile_patch,
    mechanism_drivers           => $mechanism_drivers,
    mlnx_driver                 => $mlnx['driver'],
    mlnx_sriov                  => $mlnx['sriov']
  }
}
