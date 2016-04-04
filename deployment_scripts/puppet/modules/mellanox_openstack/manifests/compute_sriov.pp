class mellanox_openstack::compute_sriov (
  $physnet,
  $physifc,
  $mlnx_driver,
  $network_type,
  $firewall_driver,
  $exclude_vf,
) {

  include nova::params
  include mellanox_openstack::params

  $sriov_agent_service  = $::mellanox_openstack::params::sriov_agent_service_name
  $sriov_agent_package  = $::mellanox_openstack::params::sriov_agent_package_name
  $libvirt_service_name = 'libvirtd'
  $libvirt_package_name = $nova::params::libvirt_package_name

  $path_to_generate_pci_script = generate ("/bin/bash", "-c", 'echo /etc/fuel/plugins/mellanox-plugin-*/generate_pci_passthrough_whitelist.py | tr -d \'\n \' ')
  $pci_passthrough_addresses = generate ("/usr/bin/python", $path_to_generate_pci_script, $exclude_vf, $physnet, $physifc)

  # configure pci_passthrough_whitelist nova compute
  if ($pci_passthrough_addresses) {
    nova_config { 'DEFAULT/pci_passthrough_whitelist':
      value      => check_array_of_hash("${pci_passthrough_addresses}"),
    } ~>
    service { $nova::params::compute_service_name:
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }
  }

  # update [securitygroup] section in neutron
  neutron_plugin_ml2 { 'securitygroup/firewall_driver':
    value => $firewall_driver,
  }

  if ( $network_type == 'ethernet' ){
    package { $sriov_agent_package:
      ensure => installed,
    }

    sriov_nic_agent_config {
      'sriov_nic/physical_device_mappings': value => "$physnet:$physifc";
      'securitygroup/firewall_driver'     : value => "neutron.agent.firewall.NoopFirewallDriver";
    }

    service { $sriov_agent_service:
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }

    Package[$sriov_agent_package] ->
    Sriov_nic_agent_config<||> ~>
    Service[$sriov_agent_service]

  } elsif ( $mlnx_driver == 'eth_ipoib' ){
    class { 'mellanox_openstack::eswitchd' :
      physnet => $physnet,
      physifc => $physifc,
    }

    class { 'mellanox_openstack::agent' :
      physnet => $physnet,
      physifc => $physifc,
    }

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
}
