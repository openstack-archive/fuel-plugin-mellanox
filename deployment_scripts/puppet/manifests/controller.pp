$eswitch_vnic_type = 'hostdev'
$eswitch_apply_profile_patch = 'True'
$mechanism_drivers = 'openvswitch'

class { 'mellanox_openstack::controller' :
  eswitch_vnic_type           => $eswitch_vnic_type,
  eswitch_apply_profile_patch => $eswitch_apply_profile_patch,
  mechanism_drivers           => $mechanism_drivers,
}
