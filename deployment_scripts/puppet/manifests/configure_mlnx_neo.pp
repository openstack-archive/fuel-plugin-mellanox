$mlnx = hiera('mellanox-plugin')

if $mlnx['use_mlnx_neo'] {

  include neutron::params
  $server_service = $neutron::params::server_service
  $neo_ip = $mlnx['mlnx_neo_ip']
  $neo_user = $mlnx['mlnx_neo_user']
  $neo_password = $mlnx['mlnx_neo_password']

  package { 'lldpd':
    ensure => installed
  } ~>
  service { 'lldpd':
    ensure => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }

  if ( 'controller' in hiera('role') ) {
    unless $mlnx['sriov']{
      neutron_plugin_ml2 {
        'ml2/mechanism_drivers': value => "sdnmechdriver,${mechanism_drivers}";
      }
    }

    neutron_plugin_ml2 {
      'sdn/url':                  value => "http://${neo_ip}/neo/";
      'sdn/domain':               value => "cloudx";
      'sdn/username':             value => "${neo_user}";
      'sdn/password':             value => "${neo_password}";
    }

    service { $server_service :
      ensure => running
    }

    Neutron_plugin_ml2 <||> ~>
    Service[$server_service]
  }
}
