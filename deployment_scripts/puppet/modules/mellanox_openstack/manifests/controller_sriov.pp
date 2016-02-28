class mellanox_openstack::controller_sriov (
  $eswitch_vnic_type,
  $eswitch_apply_profile_patch,
  $mechanism_drivers,
  $mlnx_driver,
  $mlnx_sriov,
  $mlnx_qos,
  $pci_vendor_devices,
  $agent_required,
) {

  include neutron::params
  $server_service = $neutron::params::server_service
  $dhcp_agent = $neutron::params::dhcp_agent_service

  include mellanox_openstack::params
  $package = $::mellanox_openstack::params::neutron_mlnx_packages_controller

  package { $package :
    ensure => installed,
  }

  nova_config { 'DEFAULT/scheduler_default_filters':
    value => 'RetryFilter, AvailabilityZoneFilter, RamFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, PciPassthroughFilter'
  }

  if ( $mlnx_driver == 'mlx4_en' ){
    $ml2_extra_mechanism_driver = 'sriovnicswitch'
    neutron_plugin_ml2 {
      'ml2/mechanism_drivers':                  value => "${ml2_extra_mechanism_driver},${mechanism_drivers}";
      'ml2_sriov/supported_pci_vendor_devs':    value => $pci_vendor_devices;
      'ml2_sriov/agent_required':               value => $agent_required;
    }
  }
  else {
    $ml2_extra_mechanism_driver = 'mlnx'
    neutron_plugin_ml2 {
      'eswitch/vnic_type':                      value => $eswitch_vnic_type;
      'eswitch/apply_profile_patch':            value => $eswitch_apply_profile_patch;
      'ml2/mechanism_drivers':                  value => "${ml2_extra_mechanism_driver},${mechanism_drivers}";
    }
  }

  if ( $mlnx_qos == 'true' ){
    neutron_plugin_ml2 {
      'ml2/extension_drivers':                    value => $mlnx_qos;
    }
    neutron_config { 
      'DEFAULT/service_plugins':                  value => join(['neutron.services.qos.qos_plugin:QoSPlugin',]),
    }
  }

  service { $server_service :
    ensure => running
  }

  Package[$package] ->
  Neutron_plugin_ml2 <||> ~>
  Service[$server_service]

  if ( $mlnx_driver == 'eth_ipoib' ){
    neutron_dhcp_agent_config { 'DEFAULT/dhcp_driver' :
      value     => 'networking_mlnx.dhcp.mlnx_dhcp.MlnxDnsmasq',
    }

    neutron_dhcp_agent_config { 'DEFAULT/dhcp_broadcast_reply' :
      value     => 'True',
    }

    service { $dhcp_agent :
      ensure     =>  running,
      enable     =>  true,
      provider   =>  pacemaker,
      subscribe  =>  [Neutron_dhcp_agent_config['DEFAULT/dhcp_driver'],
                      Neutron_dhcp_agent_config['DEFAULT/dhcp_broadcast_reply']],
    }
  }
}
