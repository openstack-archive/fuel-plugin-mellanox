class mellanox_openstack::compute_sriov (
  $physnet,
  $physifc,
  $mlnx_driver,
  $firewall_driver,
  $exclude_vf,
) {

  include nova::params
  $libvirt_service_name = 'libvirtd'
  $libvirt_package_name = $nova::params::libvirt_package_name

  $path_to_generate_pci_sccript = generate ("/bin/bash", "-c", 'echo /etc/fuel/plugins/mellanox-plugin-*.0/generate_pci_passthrough_whitelist.py | tr -d \'\n \' ')
  $pci_passthrough_addresses = generate ("/usr/bin/python", $path_to_generate_pci_sccript, $exclude_vf, $physnet)

  if ( $mlnx_driver == 'mlx4_en' ){
    # configure pci_passthrough_whitelist nova compute
    nova_config { 'DEFAULT/pci_passthrough_whitelist':
      value => check_array_of_hash($pci_passthrough_addresses);
      #value => $pci_passthrough_addresses;
    }

    # update [securitygroup] section in neutron
    neutron_plugin_ml2 { 'securitygroup/firewall_driver':    
       value => $firewall_driver;
    }
  }

  class { 'mellanox_openstack::eswitchd' :
      physnet => $physnet,
      physifc => $physifc,
  }

  class { 'mellanox_openstack::agent' :
      physnet => $physnet,
      physifc => $physifc,
  }

#  class { 'mellanox_openstack::snapshot_patch' : }

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
