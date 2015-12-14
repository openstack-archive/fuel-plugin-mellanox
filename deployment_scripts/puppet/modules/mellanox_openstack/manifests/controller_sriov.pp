class mellanox_openstack::controller_sriov (
  $eswitch_vnic_type,
  $eswitch_apply_profile_patch,
  $mechanism_drivers,
  $mlnx_driver,
  $mlnx_sriov,
  $pci_vendor_devices,
  $agent_required

) {

  include neutron::params
  $server_service = $neutron::params::server_service
  $dhcp_agent = $neutron::params::dhcp_agent_service

  include mellanox_openstack::params
  $package              = $::mellanox_openstack::params::neutron_mlnx_packages_controller

  ## add nova conf but how ???
  nova_config { 'DEFAULT/scheduler_default_filters': 
    value => join($scheduler_default_filters,', PciPassthroughFilter')
  }

  package { $package :
        ensure => installed,
  }

  neutron_plugin_ml2 {
    'eswitch/vnic_type':                      value => $eswitch_vnic_type;
    'eswitch/apply_profile_patch':            value => $eswitch_apply_profile_patch;

    #check if infiniband
    if ( $mlnx_driver == 'eth_ipoib' ){
      'ml2/mechanism_drivers':                  value => "mlnx,${mechanism_drivers}";
    } else if ( $mlnx_driver == 'mlx4_en' ){
      'ml2/mechanism_drivers':                  value => "sriovnicswitch,${mechanism_drivers}";
    }

    # add to ml2_sriov section
    'ml2_sriov/supported_pci_vendor_devs':    value => $pci_vendor_devices;

    # agent required
    'ml2_sriov/agent_required':               value => $agent_required;
  }

  ## retart nuetron server with conf files, how ??


  service { $server_service :
    ensure => running
  }

  Package[$package] ->
  Neutron_plugin_ml2 <||> ~>
  Service[$server_service]

  if ( $mlnx_driver == 'eth_ipoib' and $mlnx_sriov == true ){
    package { 'mlnx-dnsmasq' :
      ensure    =>  installed,
      subscribe =>  Service[$server_service]
    }

    neutron_dhcp_agent_config { 'DEFAULT/dhcp_driver' :
      value     => 'mlnx_dhcp.MlnxDnsmasq',
      subscribe =>  Package['mlnx-dnsmasq']
    }

    service { $dhcp_agent :
      ensure     =>  running,
      enable     =>  true,
      provider   =>  pacemaker,
      subscribe  =>  Neutron_dhcp_agent_config['DEFAULT/dhcp_driver'],
    }
  }

}
