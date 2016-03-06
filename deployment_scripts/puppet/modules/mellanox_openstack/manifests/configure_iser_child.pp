class mellanox_openstack::configure_iser_child (
  $iser_parent,
  $iser_child,
  $iser_ipaddr
) {
  l23_stored_config { $iser_parent:
    ipaddr   => none,
    method   => static
  } ~>
  exec { 'flush-iser-parent':
    command     => "/sbin/ip addr flush dev $iser_parent",
    refreshonly => true,
  } ->
  l23_stored_config { $iser_child:
    ipaddr   => $iser_ipaddr,
    method   => static
  } ~>
  exec { 'refresh-iser-child':
    command     => "/sbin/ifdown $iser_child ; /sbin/ifup $iser_child",
    refreshonly => true,
  }
}

