class mellanox_openstack::agent (
    $physnet,
    $physifc,
) {
    include nova::params
    include mellanox_openstack::params

    $package              = $::mellanox_openstack::params::neutron_mlnx_packages_compute
    $agent                = $::mellanox_openstack::params::agent_service
    $filters_dir          = $::mellanox_openstack::params::filters_dir
    $filters_file         = $::mellanox_openstack::params::filters_file
    $mlnx_agent_conf      = $::mellanox_openstack::params::mlnx_agent_conf
    $mlnx_agent_init_file = $::mellanox_openstack::params::mlnx_agent_init_file

    # Only relevant for Debian since no package provides network.filters file
    if $::osfamily == 'Debian' {
        File {
            owner  => 'root',
            group  => 'root',
        }

        file { $filters_dir :
            ensure => directory,
            mode   => '0755',
        }

        file { $filters_file :
            ensure => present,
            mode   => '0644',
            source => 'puppet:///modules/mellanox_openstack/network.filters',
        }

        File <| title == '/etc/nova/nova.conf' |> ->
        File[$filters_dir] ->
        File[$filters_file] ~>
        Service[$nova::params::compute_service_name]
    }

    file { $mlnx_agent_conf :
        owner => 'neutron'
    }

    exec { 'fix_mlnx_agent_init' :
      command => "sed -i s/neutron-plugin-mlnx-agent/neutron-mlnx-agent/g $mlnx_agent_init_file",
      onlyif  => "test -f $mlnx_agent_init_file && cat $mlnx_agent_init_file | grep -q neutron-plugin-mlnx-agent",
      path    => ['/bin', '/sbin', '/usr/bin']
    }

    mellanox_agent_config {
        'eswitch/physical_interface_mappings' : value => "${physnet}:${physifc}";
    }

    package { $package :
        ensure => installed,
    }

    service { $agent :
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }

    Package[$package] ->
    File[$mlnx_agent_conf] ->
    Mellanox_agent_config <||> ~>
    Exec[fix_mlnx_agent_init] ~>
    Service[$agent] ~>
    Service[$nova::params::compute_service_name]

    Package[$package] ~>
    Service[$agent]

}
