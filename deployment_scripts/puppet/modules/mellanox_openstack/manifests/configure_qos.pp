class mellanox_openstack::configure_qos (
  $mlnx_sriov
){

  neutron_plugin_ml2 {
    'ml2/extension_drivers': value => 'qos';
  }

  neutron_config {
    'DEFAULT/service_plugins': value => join(['neutron.services.qos.qos_plugin:QoSPlugin',]),
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
