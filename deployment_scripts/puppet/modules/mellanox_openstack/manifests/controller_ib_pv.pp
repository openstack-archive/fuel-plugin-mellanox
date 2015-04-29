class mellanox_openstack::controller_ib_pv (
  $mlnx_driver,
  $mlnx_sriov
){

  include neutron::params
  $dhcp_agent = $neutron::params::dhcp_agent_service
  $mlnx_dnsmasq_pv_config_file = '/etc/mlnx_dnsmasq_pv.conf'

  if ( $mlnx_driver == 'eth_ipoib' and $mlnx_sriov != true ){

    file { $mlnx_dnsmasq_pv_config_file :
      ensure    => file,
      owner     => 'neutron',
      group     => 'neutron',
      mode      => '644',
      content   => template('mellanox_openstack/mlnx_dnsmasq_pv_config.erb'),
    } ~>

    neutron_dhcp_agent_config { 'DEFAULT/dnsmasq_config_file' :
      value     => $mlnx_dnsmasq_pv_config_file,
    }

    service { $dhcp_agent :
      ensure    =>  running,
      enable    =>  true,
      subscribe =>  [File[$mlnx_dnsmasq_pv_config_file],
                     Neutron_dhcp_agent_config['DEFAULT/dnsmasq_config_file']]
    }

  }

}
