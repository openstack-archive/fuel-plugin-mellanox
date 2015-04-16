class mellanox_openstack::controller_sriov (
  $eswitch_vnic_type,
  $eswitch_apply_profile_patch,
  $mechanism_drivers,
  $mlnx_driver,
  $mlnx_sriov
) {

  include neutron::params
  $server_service = $neutron::params::server_service
  $dhcp_agent = $neutron::params::dhcp_agent_service

  neutron_plugin_ml2 {
    'eswitch/vnic_type':            value => $eswitch_vnic_type;
    'eswitch/apply_profile_patch':  value => $eswitch_apply_profile_patch;
    'ml2/mechanism_drivers':        value => "mlnx,${mechanism_drivers}";
  }

  service { $server_service :
    ensure => running
  }

  Neutron_plugin_ml2 <||> ~>
  Service[$server_service]

  if ( $mlnx_driver == 'eth_ipoib' and $mlnx_sriov == true ){
    package { 'mlnx-dnsmasq' :
      ensure    =>  installed,
      subscribe =>  Service[$server_service]
    }

    neutron_dhcp_agent_config { 'DEFAULT/dhcp_driver' :
      value     => 'dhcp_driver = mlnx_dhcp.MlnxDnsmasq',
      subscribe =>  Package['mlnx-dnsmasq']
    }

    service { $dhcp_agent :
      ensure     =>  running,
      enable     =>  true,
      subscribe  =>  Neutron_dhcp_agent_config['DEFAULT/dhcp_driver'],
    }
  }

}
