class mellanox_openstack::params {

  $eswitchd_package          = 'eswitchd'
  $filters_dir               = '/etc/nova/rootwrap.d'
  $filters_file              = "${filters_dir}/network.filters"
  $mlnx_agent_conf           = '/etc/neutron/plugins/mlnx/mlnx_conf.ini'

  case $::osfamily {
    'RedHat': {
      $neutron_mlnx_packages    = ['openstack-neutron-mellanox']
      $agent_service            = 'neutron-mlnx-agent'
      $compute_service_name     = 'openstack-nova-compute'
      $openvswitch_mgmt_service = 'openvswitch'
      $libvirt_driver_file      = '/usr/lib/python2.6/site-packages/nova/virt/libvirt/driver.py'
    }
    'Debian': {
      $neutron_mlnx_packages_compute    = ['neutron-plugin-mlnx','neutron-plugin-mlnx-agent', 'python-networking-mlnx']
      $neutron_mlnx_packages_controller = ['python-networking-mlnx']
      $agent_service                    = ['neutron-plugin-mlnx-agent']
      $sriov_agent_service_name         = 'neutron-plugin-sriov-agent'
      $sriov_agent_package_name         = 'neutron-plugin-sriov-agent'
      $compute_service_name             = 'nova-compute'
      $openvswitch_mgmt_service         = 'openvswitch-switch'
      $libvirt_driver_file              = '/usr/lib/python2.7/dist-packages/nova/virt/libvirt/driver.py'
    }
  }

}
