$network_scheme = hiera('network_scheme')
$quantum_settings = hiera('quantum_settings')
$mlnx = hiera('mellanox-plugin')
$firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
# run python to get its array value
$pci_passthrough = '{\"address\":[\"03:00.3\",\"03:00.4\",\"03:00.5\",\"03:00.6\",\"03:00.7\",\"03:01.0\",\"03:01.1\",\"03:01.2\",\"03:01.3\",\"03:01.4\",\"03:01.5\",\"03:01.6\",\"03:01.7\",\"03:02.0\"],\"physical_network\":\"physnet2\"}'
# pass it to ruby to format it

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::compute_sriov' :
    physnet => $quantum_settings['predefined_networks']['net04']['L2']['physnet'],
    physifc => $mlnx['physical_port'],
    pci_passthrough => $pci_passthrough,
    firewall_driver => $firewall_driver,
  }
}
