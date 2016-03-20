Installation Guide
==================

To install Mellanox plugin, follow these steps:

#. Install Fuel Master node. For more information on how to create a Fuel Master node, please see `Mirantis Fuel 8.0 documentation <https://docs.mirantis.com/openstack/fuel/fuel-8.0/>`_.
#. Download the plugin rpm file for MOS 8.0 from `Fuel Plugin Catalog <https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins>`_.
#. Copy the plugin on already installed Fuel Master. scp can be used for that.::

   # scp mellanox-plugin-3.0-3.0.0-1.noarch.rpm root@<Fuel_Master_ip>:/tmp
#. Install the plugin::

   # cd /tmp
   # fuel plugins --install mellanox-plugin-2.0-2.0.0-1.noarch.rpm

#. Verify the plugin was installed successfully by having it listed using ``fuel plugins`` command::

   # fuel plugins
   #  id | name              | version | package_version
   #  ---|-------------------|---------|----------------
   #  1  | mellanox-plugin   | 3.0.0   | 3.0.0

#. Create new bootstrap image for supporting infiniband networks (``create_mellanox_vpi_bootstrap can be used``):::

   [root@fuel ~]# create_mellanox_vpi_bootstrap

   ::

     Try to build image with data:
     bootstrap:
     certs: null
     container: {format: tar.gz, meta_file: metadata.yaml} 
     . . . 
     . . . 
     . . .
     Bootstrap image f790e9f8-5bc5-4e61-9935-0640f2eed949 has been activated.

#. In case of using the customized bootstrap image, you must reboot your target nodes with the new bootstrap image you just created.
   If you already have discovered nodes you can either reboot them manually or use :bash: `reboot_bootstrap_nodes` command.  Run :bash: `reboot_bootstrap_nodes -h` for help.

#. Create an environment - for more information please see `how to create an environment <https://docs.mirantis.com/openstack/fuel/fuel-8.0/user-guide.html>`_.
   We support both main network configurations:

   - `Neutron with VLAN segmentation`
   - `Neutron with tunneling segmentation`

   .. image:: ./_static/ml2_driver.png
   .. :alt: Network Configuration Type  

#. Enable KVM hypervisor type. KVM is required to enable Mellanox Openstack features.
   Open the Settings tab, select Compute section and then choose KVM hypervisor type.

   .. image:: ./_static/kvm_hypervisor.png
   .. :alt: Hypervisor Type

#. Enable desired Mellanox Openstack features.
   Open the Other tab.
   Enable Mellanox features by selecting Mellanox Openstack features checkbox.
   Select relevant plugin version if you have multiple versions installed.

   .. image:: ./_static/mellanox_features.png
   .. :alt: Enable Mellanox Openstack Features


   Now you can enable one or more features relevant for your deployment:

   #. Support SR-IOV direct port creation in private VLAN networks
      **Note**: Relevant for `VLAN segmentation` only

     - This enables Neutron SR-IOV support. 
     - **Number of virtual NICs** is amount of virtual functions (VFs) that will be available on Compute node.

     **Note**: One VF will be utilized for iSER storage transport if you choose to use iSER. In this case you will get 1 VF less for Virtual Machines.

     .. image:: ./_static/sriov.png
     .. :alt: Enable SR-IOV

   #. Support quality of service over VLAN networks with Mellanox SR-IOV direct ports (Neutron)
      **Note**: Relevant for `VLAN segmentation` only
      If selected, Neutron "Quality of service" (QoS) will be enabled for VLAN networks and ports over Mellanox HCAs.
      **Note**: This feature is supported only if: 

       - Ethernet mode is used
       - SR-IOV is enabled

      .. image:: ./_static/qos.png
      .. :alt: Enable QoS

   #. Support NEO SDN controller auto VLAN Provisioning (Neutron)
      **Note**: Relevant for `VLAN segmentation` only

      If selected, Mellanox NEO Mechanism driver will be used in order to support Auto switch VLAN auto-provisioning for Ethernet network

      To use this feature please provide IP address, username and password for NEO SDN controller. 

      .. image:: ./_static/neo.png
      .. :alt: Enable NEO Driver mechanism support

      Additional info about NEO can be found by link: https://community.mellanox.com/docs/DOC-2155

   #. Support VXLAN Offloading (Neutron)
      **Note**: Relevant for `tunneling segmentation` only
 
      If selected, Mellanox hardware will be used to achieve a better performance and significant CPU overhead reduction using VXLAN traffic offloading.

      .. image:: ./_static/vxlan.png
      .. :alt: Enable VXLAN offloading

   #. iSER protocol for volumes (Cinder)
      **Note**: Relevant for both `VLAN segmentation` and `VLAN segmentation` deployments

      By enabling this feature you.ll use iSER block storage transport instead or ISCSI.
      iSER stands for ISCSI Extension over  RDMA and improver latency, bandwidth and reduce CPU overhead.
      **Note**: In Ethernet mode, a dedicated Virtual Function will be reserved for a storage endpoint, and the priority flow control has to be enabled on the switch side port.

      **Note**: In Infiniband mode, the IPoIB parent interface of the network storage interface will be used as the storage endpoint

      .. image:: ./_static/iser.png
      .. :alt: Enable iSER


.. note:: When configuring Mellanox plugin, please mind the following:

#. You *cannot* install a plugin for existing environment without the plugin support.
   That means, the plugin will appear in the certain environment only if the plugin was installed before creating the environment. You can upgrade the plugin for existing non-deployed environments. 

#. Enabling the mellanox Openstack features hardware support on your environment, regardless of the chosen Mellanox features.

#. In Ethernet cloud, when using SR-IOV & iSER, one of the virtual NICs for SR-IOV will be reserved to the storage network.

#. When using SR-IOV you can set the number of virtual NICs (virtual functions) to up to 62
   if your hardware and system capabilities like memory and BIOS support it).
   In any case of SR-IOV hardware limitation, the installation will try to fallback a VF number to the default of 8 VFs.

