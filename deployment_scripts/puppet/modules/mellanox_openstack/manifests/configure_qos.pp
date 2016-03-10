class mellanox_openstack::configure_qos (
  $mlnx_sriov,
  $roles
){

  if 'compute' in $roles {
    sriov_nic_agent_config {
      'agent/extensions': value => 'qos';
    }

    Sriov_nic_agent_config <||> ~> Service['neutron-plugin-sriov-agent']
  }

  if 'controller' in $roles or 'primary-controller' in $roles {
    neutron_plugin_ml2 {
      'ml2/extension_drivers': value => 'qos';
    }

    neutron_config {
      'DEFAULT/service_plugins': value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',',','neutron.services.qos.qos_plugin.QoSPlugin',]),
    }

    unless $mlnx_sriov {
      include neutron::params
      include mellanox_openstack::params
      $server_service = $neutron::params::server_service
      $package = $::mellanox_openstack::params::neutron_mlnx_packages_controller

      package { $package :
        ensure => installed,
      }

      service { $server_service :
        ensure => running
      }

      Package[$package] ->
      Neutron_plugin_ml2 <||> ~>
      Service[$server_service]
    }
  }
}
