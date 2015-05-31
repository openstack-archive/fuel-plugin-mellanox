class mellanox_openstack::compute_sriov (
  $physnet,
  $physifc,
) {

  include nova::params
  $libvirt_service_name = $nova::params::libvirt_service_name
  $libvirt_package_name = $nova::params::libvirt_package_name

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
