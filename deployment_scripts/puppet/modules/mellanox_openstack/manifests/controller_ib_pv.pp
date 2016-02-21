class mellanox_openstack::controller_ib_pv (){

  include neutron::params
  $dhcp_agent = $neutron::params::dhcp_agent_service

  neutron_dhcp_agent_config { 'DEFAULT/dhcp_broadcast_reply' :
    value     => 'True',
  }

  service { $dhcp_agent :
    ensure     =>  running,
    enable     =>  true,
    provider   =>  pacemaker,
    subscribe  =>  [Neutron_dhcp_agent_config['DEFAULT/dhcp_broadcast_reply']],
  }
}
