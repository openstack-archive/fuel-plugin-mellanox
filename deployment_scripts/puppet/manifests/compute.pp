$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')
$firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
# run python to get its array value
#$pci_passthrough = 
# pass it to ruby to format it

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::compute_sriov' :
    physnet => $quantum_settings['predefined_networks']['net04']['L2']['physnet'],
    physifc => $mlnx['physical_port'],
    pci_passthrough => $pci_passthrough,
    firewall_driver => $firewall_driver,
  }
}
