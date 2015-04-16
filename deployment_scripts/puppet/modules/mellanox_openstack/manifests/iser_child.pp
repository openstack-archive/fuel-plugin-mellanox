class mellanox_openstack::iser_child ($storage_parent, $iser_pkey){

  $interfaces_path = '/sys/class/net/'
  $iser_script_dir = '/opt/iser'
  $iser_child_script = "$iser_script_dir/iser_child_create.sh"

  if $iser_pkey {
    file { $iser_script_dir:
      ensure => directory,
    }

    file { $iser_child_script:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '500',
      content => template('mellanox_openstack/iser_child_create.erb'),
    }

    exec { 'iser_child_create':
      command   => "bash $iser_child_script",
      path      => ['/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin'],
      logoutput => true,
      require   => File[$iser_child_script],
    }
  }
}

