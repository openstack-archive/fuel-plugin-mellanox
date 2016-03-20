Mellanox plugin configuration
=============================

If you plan to enable VM to VM RDMA and to use iSER storage transport you need to configure switching fabric to support the features.

**Ethernet network:**

#. Configure the required VLANs and enable flow control on the Ethernet switch ports.
#. All related VLANs should be enabled on the Mellanox switch ports (for relevant Fuel logical networks).
#. Login to the Mellanox switch by ssh and execute following commands:::

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

**Infiniband network:**
If you use OpenSM you need to enable virtualization and allow all PKeys:

#. Create a new opensm.conf file::

   # opensm -c /etc/opensm/opensm.conf
#. Enable virtualization by editing /etc/opensm/opensm.conf and changing the allow_both_pkeys value to TRUE.::

   # allow_both_pkeys TRUE

#. Define the partition keys which are analog for Ethernet VLAN. Each VLAN will be mapped to one PK. Add/Change the following with the command ::

   # vi /etc/opensm/partitions.conf file:
   # (Example)
   # management=0x7fff,ipoib, sl=0, defmember=full : ALL, ALL_SWITCHES=full,SELF=full;
   # vlan1=0x1, ipoib, sl=0, defmember=full : ALL;
   # vlan2=0x2, ipoib, sl=0, defmember=full : ALL;
   # . . .
   # vlan100=0x64, ipoib, sl=0, defmember=full : ALL;
#. RestartpenSM::

   # /etc/init.d/opensmd restart
