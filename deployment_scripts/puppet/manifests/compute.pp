$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')

if ($mlnx['sriov']) {
  $firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
  $pci_passthrough_addresses = generate ("/bin/bash", "-c", 'python /etc/fuel/plugins/mellanox-plugin-*.0/generate_pci_passthrough_whitelist.py "0"')
  #$physnet = $quantum_settings['predefined_networks']['net04']['L2']['physnet']
  #$pci_passthrough_list = '{ "address":"${pci_passthrough_addresses},"physical_network":"${physnet}"}'
  class { 'mellanox_openstack::compute_sriov' :
    physnet => $quantum_settings['predefined_networks']['net04']['L2']['physnet'],
    physifc => $mlnx['physical_port'],
    pci_passthrough => $pci_passthrough_addresses,
    firewall_driver => $firewall_driver,
  }
}

