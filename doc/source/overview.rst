.. _overview:

Mellanox plugin
===============

Beginning with version 5.1, Fuel can configure Mellanox ConnectX-3 Pro network adapters to
accelerate the performance of compute and storage traffic.This implements the
following performance enhancements:

- Compute nodes use SR-IOV based networking.
- Cinder nodes use iSER block storage as the iSCSI transport rather than the default iSCSI over TCP.

These features reduce CPU overhead, boost throughput, reduce latency, and
enable network traffic to bypass the software switch layer (e.g. Open vSwitch).
Starting with version 6.1, Mellanox plugin can deploy those features over
Infiniband network as well.

However, for Fuel version 7.0, plugin uses Mirantis bootstrap images and
therefore only Ethernet Network is supported.

Requirements
------------

+-----------------------------------+-----------------+
| Requirement                       | Version/Comment |
+===================================+=================+
| Mirantis OpenStack compatibility  |   7.0           |
+-----------------------------------+-----------------+

The Mellanox ConnectX-3 Pro adapters family supports up to 40/56GbE.
To reach 56 GbE speed in your network with ConnectX-3 Pro adapters, you must use Mellanox Ethernet / Infiniband switches (e.g. SX1036)
with the additional 56GbE license.
The switch ports should be configured specifically to use 56GbE speed. No additional configuration is required on the adapter side.
For additional information about how to run in 56GbE speed, see
`HowTo Configure 56GbE Link on Mellanox Adapters and Switches <http://community.mellanox.com/docs/DOC-1460>`_.

For detailed setup configuration and BOM (Bill of Material) requirements please see
`Fuel Ethernet cloud details <https://community.mellanox.com/docs/DOC-1474>`_ or
`Fuel Infiniband cloud details <https://community.mellanox.com/docs/DOC-2036>`_.
