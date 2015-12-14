$mlnx = hiera('mellanox-plugin')
$eswitch_vnic_type = 'hostdev'
$eswitch_apply_profile_patch = 'True'
$mechanism_drivers = 'openvswitch'
$pci_vendor_devices = generate("/bin/lspci -nn | grep -i Mellanox | grep -i virtual | awk '{print $NF}' | sort -u ")
$agent_required = 'True'

if ($mlnx['sriov']) {
  class { 'mellanox_openstack::controller_sriov' :
    eswitch_vnic_type           => $eswitch_vnic_type,
    eswitch_apply_profile_patch => $eswitch_apply_profile_patch,
    mechanism_drivers           => $mechanism_drivers,
    mlnx_driver                 => $mlnx['driver'],
    mlnx_sriov                  => $mlnx['sriov'],
    pci_vendor_devices          => $pci_vendor_devices,
    agent_required              => $agent_required
  }
}
# Configure broadcast dnsmasq for IB PV
elsif ($mlnx['driver'] == 'eth_ipoib') {
  class { 'mellanox_openstack::controller_ib_pv' :
    mlnx_driver                 => $mlnx['driver'],
    mlnx_sriov                  => $mlnx['sriov']
  }
}
