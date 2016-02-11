class mellanox_openstack::cinder_iser (
  $iser_ip_address,
) {
  include cinder::params

  cinder_config { 'DEFAULT/volume_driver' :
    value => 'cinder.volume.drivers.lvm.LVMVolumeDriver'
  }
  cinder_config { 'DEFAULT/iscsi_protocol' :
    value => 'iser'
  }
  cinder_config { 'DEFAULT/iscsi_ip_address' :
    value => "$iser_ip_address"
  }
  exec { 'flush_br_storage' :
    command => "ip addr flush dev br-storage",
    onlyif  => "ip a | grep -q br-storage",
    path    => ['/bin', '/sbin']
  }
  service { $cinder::params::volume_service :
    ensure    => running,
    subscribe => [Cinder_config['DEFAULT/iscsi_protocol'],
                  Cinder_config['DEFAULT/volume_driver'],
                  Exec['flush_br_storage'],
                  Cinder_config['DEFAULT/iscsi_ip_address']]
  }
}
