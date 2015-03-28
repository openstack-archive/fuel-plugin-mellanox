$mlnx = hiera('mellanox_plugin')
$num_of_vfs = $mlnx['num_of_vfs']

# Set the number of probed vfs
if ($mlnx['iser'] == true) {
  $probe_vfs = 1
} else {
  $probe_vfs = 0
}

# Set the port type according to the driver in use
if ($mlnx['driver'] == 'mlx4_en') {
  $port_type = 2
} elsif ($mlnx['driver'] == 'eth_ipoib') {
  $port_type = 1
} else {
  fail("unknown port type: $port_type")
}

# Execute the SR-IOV script, that configures the modprobe file
# and the grub file
File {
    owner  => 'root',
    group  => 'root',
}
file { '/opt/mlnx/' :
    ensure => directory,
    mode   => '0755',
} ->
file { '/opt/mlnx/sriov.sh' :
    ensure => present,
    mode   => '0644',
    content => template('mellanox_openstack/sriov.erb'),
} ->
exec { 'sriov':
  command   => "bash -x /opt/mlnx/sriov.sh",
  path      => ['/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin'],
  logoutput => true,
}

