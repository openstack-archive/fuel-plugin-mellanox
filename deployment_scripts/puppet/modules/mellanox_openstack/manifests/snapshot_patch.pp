class mellanox_openstack::snapshot_patch {

  $libvirt_driver_file  = $::mellanox_openstack::params::libvirt_driver_file
  $compute_service_name = $::mellanox_openstack::params::compute_service_name
  $sriov_patch_file     = "/tmp/sriov.patch"

  file { $sriov_patch_file :
    source      => "puppet:///modules/mellanox_openstack/sriov.patch",
    notify      => Exec["apply-snapshot-patch"],
  }

  exec { "apply-snapshot-patch" :
    command     => "patch $libvirt_driver_file $sriov_patch_file",
    unless      => "grep -i 'hostdev' $libvirt_driver_file | grep -q -i vif",
    path        => ["/bin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/sbin"],
    refreshonly => true,
    notify      => Service[$compute_service_name]
  }

}
