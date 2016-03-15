$mlnx = hiera('mellanox-plugin')
$eswitch_vnic_type = 'hostdev'
$eswitch_apply_profile_patch = 'True'
$mechanism_drivers = 'openvswitch'

# Configure QoS for ETH
if ( $mlnx['driver'] == 'mlx4_en' and $mlnx['mlnx_qos'] ) {
  class { 'mellanox_openstack::configure_qos' :
    mlnx_sriov => $mlnx['sriov']
  }
}

if ($mlnx['sriov']) {
  $pci_vendor_devices = '15b3:1004,15b3:1014,8086:10ca'
  $agent_required = 'True'
  class { 'mellanox_openstack::controller_sriov' :
    eswitch_vnic_type           => $eswitch_vnic_type,
    eswitch_apply_profile_patch => $eswitch_apply_profile_patch,
    mechanism_drivers           => $mechanism_drivers,
    mlnx_driver                 => $mlnx['driver'],
    mlnx_sriov                  => $mlnx['sriov'],
    pci_vendor_devices          => $pci_vendor_devices,
    agent_required              => $agent_required,
    use_mlnx_neo                => $mlnx['use_mlnx_neo']
  }
}
# Configure broadcast dnsmasq for IB PV
elsif ($mlnx['driver'] == 'eth_ipoib') {
  class { 'mellanox_openstack::controller_ib_pv' : }
}
