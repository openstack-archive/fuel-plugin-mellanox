$ofed_package = 'mlnx-ofed-light'

package { $ofed_package :
    ensure => installed,
}

exec { 'install_ofed':
  command   => "/opt/ofed/install_ofed.sh",
  path      => ['/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin'],
  logoutput => true,
}

Package[$ofed_package] ->
Exec['install_ofed']
