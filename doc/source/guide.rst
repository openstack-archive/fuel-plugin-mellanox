.. _configuration:

Mellanox plugin configuration
=============================

To configure Mellanox backend, follow these steps:

**Ethernet network:**

* Configure the required VLANs and enable flow control on the Ethernet switch ports.
  All related VLANs should be enabled on the 40/56GbE switch (Private, Management, Storage networks).

* On Mellanox switches, use the commands in Mellanox `reference configuration <https://community.mellanox.com/docs/DOC-1460>`_
  flow to enable VLANs (e.g. VLAN 1-100 on all ports).

* An example of configuring the switch for Ethernet deployment can be found in
  the `Mirantis Planning Guide <https://docs.mirantis.com/openstack/fuel/fuel-7.0/planning-guide.html#planning-guide>`_.


Environment creation and configuration
--------------------------------------

#. `Create an environment <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#create-a-new-openstack-environment>`_.

#. Open the Settings tab of the Fuel web UI and scroll down the page.
   In Mellanox OpenStack features section, select the required features:

   .. image:: ./_static/mellanox_features_section.png
   .. :alt: A screenshot of mellanox features section

    * The SR-IOV feature supports only KVM hypervisor and Neutron with VLAN segmentation (the latter should be enabled
      at `environment creation step <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#create-a-new-openstack-environment>`_:

      .. image:: ./_static/hypervisor_type.png
      .. :alt: A screenshot of hypervisors type

      .. image:: ./_static/network_type.png
      .. :alt: A screenshot network type

   * The iSER feature requires “Cinder LVM over iSCSI for volumes” enabled in the “Storage” section:

     .. image:: ./_static/storage_backends.png
     .. :alt: A screenshot of storage backends


.. note:: When configuring Mellanox plugin, please mind the following:

#. You *cannot* install a plugin at the already existing environment.
   That means, the plugin will appear in the certain environment only if the plugin was installed before creating the environment.

#. Enabling the “Mellanox Openstack features” section enables Mellanox
   hardware support on your environment, regardless of the iSER & SR-IOV features.

#. In Ethernet cloud, when using SR-IOV & iSER, one of the virtual NICs for SR-IOV will be reserved to the storage network.

#. When using SR-IOV you can set the number of virtual NICs (virtual functions) to up to 64
   if your hardware and system capabilities like memory and BIOSsupport it).
   In any case of SR-IOV hardware limitation, the installation will try to fallback the VF number to the default of 16 VFs.
