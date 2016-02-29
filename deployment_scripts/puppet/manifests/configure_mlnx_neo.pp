$mlnx = hiera('mellanox-plugin')

if $mlnx['use_mlnx_neo'] {
  $neo_ip = $mlnx['mlnx_neo_ip']

  package { 'lldpad':
    ensure => installed
  } ~>
  service { 'lldpad':
    ensure => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }

  unless $mlnx['sriov']{
    neutron_plugin_ml2 {
      'ml2/mechanism_drivers':                  value => "sdnmechdriver,${mechanism_drivers}";
    }
  }

  neutron_plugin_ml2 {
    'sdn/url':                  value => "http://#{neo_ip}/neo/";
    'sdn/domain':               value => "cloudx";
    'sdn/username':             value => "admin";
    'sdn/password':             value => "123456";
  }
}
