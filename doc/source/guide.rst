.. raw:: pdf

    PageBreak

Mellanox plugin configuration
=============================

If you plan to enable VM to VM RDMA and to use iSER storage transport you need to configure switching fabric to support the features.

Ethernet network:
-----------------

#. Configure the required VLANs and enable flow control on the Ethernet switch ports.
#. All related VLANs should be enabled on the Mellanox switch ports (for relevant Fuel logical networks).
#. Login to the Mellanox switch by ssh and execute following commands:

   .. note:: In case of using NEO auto provisioning, private network VLANs can be considered as dynamically configured.

   ::

    switch > enable
    switch # configure terminal
    switch (config) # vlan 1-100
    switch (config vlan 1-100) # exit
    switch (config) # interface ethernet 1/1 switchport mode hybrid
    switch (config) # interface ethernet 1/1 switchport hybrid allowed-vlan all
    switch (config) # interface ethernet 1/2 switchport mode hybrid
    switch (config) # interface ethernet 1/2 switchport hybrid allowed-vlan all
    ...
    switch (config) # interface ethernet 1/36 switchport mode hybrid
    switch (config) # interface ethernet 1/36 switchport hybrid allowed-vlan all

   Flow control is required when running iSER (RDMA over RoCE - Ethernet). On Mellanox switches, run the following command to enable flow control on the switches (on all ports in this example):::

    switch (config) # interface ethernet 1/1-1/36 flowcontrol receive on force
    switch (config) # interface ethernet 1/1-1/36 flowcontrol send on force

   save the configuration (permanently), run:::

    switch (config) # configuration write

   .. note:: When using an untagged storage network for iSER over Ethernet - please add the following commands for Mellanox switches or use trunk mode instead of hybrid.

   ::

    interface ethernet 1/1 switchport hybrid allowed-vlan add 1
    interface ethernet 1/2 switchport hybrid allowed-vlan add 1
    ...


Infiniband network:
-------------------

Mellanox **UFM** is a pre-requisite for using the Mellanox plugin for Fuel 8.0 with InfiniBand fabrics. Mellanox.s Unified Fabric Manager (UFM®) is a powerful platform for managing scale-out computing environments. UFM enables data center operators to monitor, efficiently provision, and operate the modern data center fabric. UFM is licensed per managed fabric node. For more information on how to obtain UFM, please visit Mellanox.com.

Update OpenSM configurations on UFM node as follows:

#. Update opensm.conf file and make sure of the following::

    vim /opt/ufm/conf/opensm/opensm.conf
    - virt_enabled 2
    - no_partition_enforcement TRUE
    - part_enforce off
    - allow_both_pkeys FALSE

#. Update the partitions.conf file::

      vim /opt/ufm/conf/partitions.conf.user_ext

      Example:

      vlan1=0x1, ipoib, sl=0, defmember=full: ALL_CAS;
      vlan2=0x2, ipoib, sl=0, defmember=full: ALL_CAS;
      vlan3=0x3, ipoib, sl=0, defmember=full: ALL_CAS;

      vlan4=0x4, ipoib, sl=0, defmember=full: SELF;
      vlan5=0x5, ipoib, sl=0, defmember=full: SELF;
      vlan6=0x6, ipoib, sl=0, defmember=full: SELF;
      vlan7=0x7, ipoib, sl=0, defmember=full: SELF;
      vlan8=0x8, ipoib, sl=0, defmember=full: SELF;
      vlan9=0x9, ipoib, sl=0, defmember=full: SELF;
      . . .
      vlan20=0x14, ipoib, sl=0, defmember=full: SELF;

 **Note**: In this example

 - Infra networks VLANs are 1-3 so VLAN2 is assigned to PK 0x2 and will be used for Openstack Management network and VLAN3 is assigned to PK 0x3 and will be used for Openstack Storage network.
 - Private VLANs are 4-20 so VLANs 4 through 20 are assigned to PKs 0x4 to 0x14 will be used for Tenant networks.
 - VLAN1 is defined, but not used for consistency with Ethernet setup installation.
 - The maximum number of VLANs is 128.

#. Restart ufmd::

    /etc/init.d/ufmd restart
