Mellanox plugin
===============

| The Mellanox Fuel plugin is a bundle of scripts, packages and metadata that will extend Fuel
 and add Mellanox features such as SR-IOV for networking and iSER protocol for storage.

| Fuel can configure `Mellanox ConnectX-3 Pro
 <http://www.mellanox.com/page/products_dyn?product_family=161&mtag=connectx_3_pro_vpi_card>`_
 network adapters to accelerate the performance of compute and storage traffic.

This implements the following performance enhancements:

-  Compute nodes network enhancements:
    -    SR-IOV based networking
    -    QoS for VM traffic
    -    VXLAN traffic offload
-  Cinder nodes use iSER block storage as the iSCSI transport rather than the default iSCSI over TCP.

| These features reduce CPU overhead, boost throughput, reduce latency, and enable network
 traffic to bypass the software switch layer (e.g. Open vSwitch).

| Mellanox Plugin integration with Mellanox NEO SDN Controller enables switch VLAN auto
 provisioning and port configuration for Ethernet and SM PK auto provisioning for InfiniBand
 networks, over private VLAN networks.

Developer's specification
-------------------------

| Please refer to: `HowTo Install Mellanox OpenStack Plugin for Mirantis Fuel 8.0
 <https://community.mellanox.com/docs/DOC-2435>`_

Requirements
------------

| The Mellanox ConnectX-3 Pro adapters family supports up to 40/56 Gb. To reach 56 Gb speed in
 your network with ConnectX-3 Pro adapters, you must use Mellanox Ethernet / Infiniband switches
 supporting 56 Gb (e.g. SX1710, SX6710). The switch ports should be configured specifically to use
 56 Gb speed. No additional configuration is required on the adapter side. For additional
 information about how to run in 56GbE speed, see `HowTo Configure 56GbE Link on Mellanox Adapters
 and Switches <http://community.mellanox.com/docs/DOC-1460>`_.

Limitations
-----------

- Mellanox SR-IOV and iSER are supported only when choosing Neutron with VLAN segmentation.
- ConnectX-3 Pro adapters are required in order to enable VXLAN HW offload over Ethernet networks.
- QoS feature is implemented only for Ethernet VLAN SR-IOV ports using ConnectX-3 Pro adapters.
- Infiniband is configured by using OpenSM only.
