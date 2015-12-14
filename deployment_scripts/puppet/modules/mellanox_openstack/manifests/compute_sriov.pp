class mellanox_openstack::compute_sriov (
  $physnet,
  $physifc,
  $pci_passthrough,
  $firewall_driver,
) {

  include nova::params
  $libvirt_service_name = 'libvirtd'
  $libvirt_package_name = $nova::params::libvirt_package_name

  # configure pci_passthrough_whitelist nova compute
  nova_config { 'DEFAULT/pci_passthrough_whitelist': 
      value => check_array_of_hash($pci_passthrough);
  }

  # update [securitygroup] section in neutron
  # not sure if this or in next line neutron_agent_linuxbridge { 'securitygroup/firewall_driver': value => $firewall_driver }
  neutron_plugin_ml2 {
    'securitygroup/firewall_driver':    value => $firewall_driver;
  }

  class { 'mellanox_openstack::eswitchd' :
      physnet => $physnet,
      physifc => $physifc,
  }

  class { 'mellanox_openstack::agent' :
      physnet => $physnet,
      physifc => $physifc,
  }

  class { 'mellanox_openstack::snapshot_patch' : }

  package { $libvirt_package_name :
      ensure => installed
  }

  service { $libvirt_service_name :
      ensure => running
  }

  Package[$libvirt_package_name] ->
  Service[$libvirt_service_name] ->
  Class['mellanox_openstack::eswitchd'] ~>
  Class['mellanox_openstack::agent']

}
