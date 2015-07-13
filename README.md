Mellanox Plugin for Fuel
=======================

Mellanox plugin
--------------

Beginning with version 5.1, Fuel can configure Mellanox ConnectX-3 Pro network
adapters to accelerate the performance of compute and storage traffic.
This implements the following performance enhancements:
- Compute nodes use SR-IOV based networking.
- Cinder nodes use iSER block storage as the iSCSI transport rather than the
default iSCSI over TCP.

These features reduce CPU overhead, boost throughput, reduce latency, and
enable network traffic to bypass the software switch layer (e.g. Open vSwitch).
Starting with version 6.1, Mellanox plugin can deploy those features over
Infiniband network as well.

Requirements
------------

| Requirement                      | Version/Comment |
|:---------------------------------|:----------------|
| Mirantis OpenStack compatibility | >= 6.1          |

The Mellanox ConnectX-3 Pro adapters family supports up to 40/56GbE.
To reach 56 GbE speed in your network with ConnectX-3 Pro adapters, you must
use Mellanox Ethernet / Infiniband switches (e.g. SX1036) with the additional
56GbE license. The switch ports should be configured specifically to use 56GbE
speed. No additional configuration is required on the adapter side.
For additional information about how to run in 56GbE speed, see [HowTo
Configure 56GbE Link on Mellanox Adapters and Switches](http://community.mellanox.com/docs/DOC-1460).

For detailed setup configuration and BOM (Bill of Material) requirements please see
[Fuel Ethernet cloud details](https://community.mellanox.com/docs/DOC-1474) or
[Fuel Infiniband cloud details](https://community.mellanox.com/docs/DOC-2036).

Installation Guide
==================

Mellanox plugin installation
---------------------------

To install Mellanox plugin, follow these steps:

1. Download the plugin from
    [Fuel Plugins Catalog](https://software.mirantis.com/fuel-plugins)

2. Copy the plugin on already installed Fuel Master node; ssh can be used for
    that. If you do not have the Fuel Master node yet, see
    [Quick Start Guide](https://software.mirantis.com/quick-start/) :

        # scp mellanox-plugin-1.0-1.0.0-0.noarch.rpm root@<Fuel_Master_ip>:/tmp

3. Install the plugin:

        # cd /tmp
        # fuel plugins --install mellanox-plugin-1.0-1.0.0-0.noarch.rpm
        NOTE: Mellanox plugin installation replaces your bootstrap image.
              The original image is backed up in /opt/old_bootstrap_image/.

4. Check if the plugin was installed successfully:

        # fuel plugins
        id | name              | version | package_version
        ---|-------------------|---------|----------------
        1  | mellanox-plugin   | 1.0.0   | 2.0.0

Mellanox plugin configuration
----------------------------

For instructions, more information and release notes, see the Mellanox Plugin Installation Guide
in the
[Fuel Plugins Catalog](https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/)

Contributors
------------

David Slama <dudus@mellanox.com> (PM)
Aviram Bar-Haim <aviramb@mellanox.com> (Release manager)
Andrey Yevsyukov <andreyy@mellanox.com> (Developer)
Gil Meir <gmeir11@gmail.com> (Developer)
Amichay Polishuk <amichayp@mellanox.com> (QA engineer)
Noam Angel <amichayp@mellanox.com> (QA engineer)
Lenny Verkhovsky <lennyb@mellanox.com> (Verification engineer)
Rawan Herzallah <rherzallah@asaltech.com> (Verification engineer)
Murad Awawdeh <mawawdeh@asaltech.com> (Verification engineer)
