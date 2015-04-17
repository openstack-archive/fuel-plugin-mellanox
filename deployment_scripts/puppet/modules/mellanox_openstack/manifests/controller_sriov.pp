class mellanox_openstack::controller_sriov (
  $eswitch_vnic_type,
  $eswitch_apply_profile_patch,
  $mechanism_drivers,
) {

  include neutron::params
  $server_service = $neutron::params::server_service

  neutron_plugin_ml2 {
    'eswitch/vnic_type':          value => $eswitch_vnic_type;
    'eswitch/apply_profile_patch': value => $eswitch_apply_profile_patch;
    'ml2/mechanism_drivers':      value => "mlnx,${mechanism_drivers}";
  }

  service { $server_service :
    ensure => running
  }

  Neutron_plugin_ml2 <||> ~>
  Service[$server_service]
}
