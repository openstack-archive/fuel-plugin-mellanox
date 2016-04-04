Mellanox Plugin for Fuel
=======================

Mellanox plugin overview
------------------------

The Mellanox Fuel plugin is a bundle of scripts, packages and metadata that will extend Fuel
and add Mellanox features such as SR-IOV for networking and iSER protocol for storage.
Fuel can configure Mellanox ConnectX-3 Pro network adapters to accelerate the performance of
compute and storage traffic.
This implements the following performance enhancements:

-  Compute nodes network enhancements:
    -    SR-IOV based networking
    -    QoS for VM traffic
    -    VXLAN traffic offload
-  Cinder nodes use iSER block storage as the iSCSI transport rather than the default iSCSI over
TCP.

These features reduce CPU overhead, boost throughput, reduce latency, and enable network traffic
to bypass the software switch layer (e.g. Open vSwitch). Mellanox Plugin integration with Mellanox
NEO SDN Controller enables switch VLAN auto provisioning and port configuration for Ethernet and SM
PKey auto provisioning for InfiniBand networks, over private VLAN networks.

Developer's specification
-------------------------

Please refer to:
[HowTo Install Mellanox OpenStack Plugin for Mirantis Fuel
 8.0](https://community.mellanox.com/docs/DOC-2435)

Requirements
------------

| Requirement                      | Version/Comment |
|----------------------------------|-----------------|
| Mirantis OpenStack compatibility |  8.0            |

The Mellanox ConnectX-3 Pro adapters family supports up to 40/56 Gb. To reach 56 Gb speed in
your network with ConnectX-3 Pro adapters, you must use Mellanox Ethernet / Infiniband switches
supporting 56 Gb (e.g. SX1710, SX6710). The switch ports should be configured specifically to use
56 Gb speed. No additional configuration is required on the adapter side. For additional
information about how to run in 56GbE speed, see [HowTo Configure 56GbE Link on Mellanox Adapters
and Switches](http://community.mellanox.com/docs/DOC-1460).

Limitations
-----------

- Mellanox SR-IOV is supported only when choosing Neutron with VLAN segmentation.
- ConnectX-3 Pro adapters are required in order to enable VXLAN HW offload over Ethernet networks.
- QoS feature is implemented only for Ethernet VLAN SR-IOV ports using ConnectX-3 Pro adapters.
- Infiniband is configured by using OpenSM only.

Mellanox plugin configuration
=============================

For detailed setup configuration of Ethernet or Infiniband networks, please refer to Mellanox plugin
configuration section in
[HowTo Install Mellanox OpenStack Plugin for Mirantis Fuel
 8.0](https://community.mellanox.com/docs/DOC-2435)

Installation Guide
==================

To install Mellanox plugin, follow these steps:

1. Install Fuel Master node. For more information on how to create a Fuel Master node, please see
[Mirantis Fuel 8.0 documentation](https://docs.mirantis.com/openstack/fuel/fuel-8.0/)


2. Download the plugin rpm file for MOS 8.0 from
[Fuel Plugin Catalog](https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins)


3. Copy the plugin on already installed Fuel Master. scp can be used for that:

     ```
     # scp mellanox-plugin-3.0-3.0.0-1.noarch.rpm root@<Fuel_Master_ip>:/tmp
     ```

4. Install the plugin:

     ```
     # cd /tmp
     # fuel plugins --install mellanox-plugin-3.0-3.0.0-1.noarch.rpm
     ```

5. Verify the plugin was installed successfully by having it listed using ``fuel plugins`` command:

     ```
     # fuel plugins
     #  id | name              | version | package_version
     #  ---|-------------------|---------|----------------
     #  1  | mellanox-plugin   | 3.0.0   | 3.0.0
     ```

6. Create new bootstrap image for supporting infiniband networks ``create_mellanox_vpi_bootstrap``
can be used

     ```
     [root@fuel ~]# create_mellanox_vpi_bootstrap
        Try to build image with data:
        bootstrap:
        certs: null
        container: {format: tar.gz, meta_file: metadata.yaml}
        . . .
        . . .
        . . .
        Bootstrap image f790e9f8-5bc5-4e61-9935-0640f2eed949 has been activated.
     ```

7. In case of using the customized bootstrap image, you must reboot your target nodes with the
new bootstrap image you just created. If you already have discovered nodes you can either reboot
them manually or use `reboot_bootstrap_nodes` command.  Run `reboot_bootstrap_nodes -h` for help.


User Guide
==========

Please read the [Mellanox Plugin User Guide](doc/source).

Reporting Bugs
==============

Bugs should be Reported for [Fuel Plugin Mellanox](https://launchpad.net/~fuel-plugin-mellanox).

Contributors
============

* David Slama <dudus@mellanox.com> (PM)
* Aviram Bar-Haim <aviramb@mellanox.com> (Release manager and Developer)
* Rawan Herzallah <rawanh@mellanox.com> (Developer)
* Amichay Polishuk <amichayp@mellanox.com> (QA engineer)
* Noam Angel <noama@mellanox.com> (QA engineer)
* Tamara Wari <tamarasu@mellanox.com> (Verification engineer)
