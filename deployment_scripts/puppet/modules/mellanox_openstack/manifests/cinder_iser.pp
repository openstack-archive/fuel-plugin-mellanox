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

  cinder_config { 'LVM-backend/iscsi_protocol' :
    value => 'iser'
  }

  service { $cinder::params::volume_service :
    ensure    => running,
    subscribe => [Cinder_config['DEFAULT/iscsi_protocol'],
                  Cinder_config['DEFAULT/volume_driver'],
                  Cinder_config['DEFAULT/iscsi_ip_address']]
  }
}
