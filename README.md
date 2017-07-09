Mellanox Plugin for Fuel
=======================

Mellanox plugin overview
------------------------

The Mellanox Fuel plugin is a bundle of scripts, packages and metadata that will extend Fuel
and add Mellanox features such as SR-IOV for networking and iSER protocol for storage.
Fuel can configure Mellanox ConnectX-5 network adapters to accelerate the performance of
compute and storage traffic.
This implements the following performance enhancements:

-  Compute nodes network enhancements:
    -    SR-IOV based networking
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

The Mellanox ConnectX-5 adapters family supports up to 100 Gb/s. To reach 100 Gb/s speed in your
network with ConnectX-5 adapters, you must use Mellanox Ethernet / Infiniband switches supporting
100 Gb (e.g. SN2700 (ETH), SB7700 (IB)). The switch ports should be configured specifically to
use 100 Gb speed. No additional configuration is required on the adapter side.

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
     # scp mellanox-plugin-3.2-3.2.0-1.noarch.rpm root@<Fuel_Master_ip>:/tmp
     ```

4. Install the plugin:

     ```
     # cd /tmp
     # fuel plugins --install mellanox-plugin-3.2-3.2.0-1.noarch.rpm
     ```

5. Verify the plugin was installed successfully by having it listed using ``fuel plugins`` command:

     ```
     # fuel plugins
     #  id | name              | version | package_version
     #  ---|-------------------|---------|----------------
     #  1  | mellanox-plugin   | 3.2.0   | 3.0.0
     ```

6. Create new bootstrap image for supporting infiniband networks ``create_mellanox_vpi_bootstrap``
can be used
    Example:

     ```
     [root@fuel ~]# create_mellanox_bootstrap --link_type eth --max_num_vfs 31
        Try to build image with data:
        bootstrap:
        certs: null
        container: {format: tar.gz, meta_file: metadata.yaml}
        . . .
        . . .
        . . .
        Bootstrap image f790e9f8-5bc5-4e61-9935-0640f2eed949 has been activated.

     [root@fuel ~]# create_mellanox_bootstrap --help

     usage: create_mellanox_bootstrap [-h] [--link_type {eth,ib,current}]
                                   [--max_num_vfs MAX_NUM_VFS]
     Available link_type values are:
     -------------------------------
     - eth for changing link type to Ethernet
     - ib for changing link type to Infiniband
     - current for leaving link type as is

     optional arguments:
       -h, --help show this help message and exit
       --link_type {eth,ib,current}
       --max_num_vfs MAX_NUM_VFS
                          an integer for the maximum number of vfs to be
                          burned in bootstrap
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
* Alexander Fridman <sasha@mellanox.com> (E2E engineer)
* Igor Braginsky<igorbr@mellanox.com> (E2E engineer)
