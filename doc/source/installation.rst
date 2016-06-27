.. raw:: pdf

    PageBreak

Installation Guide
==================

To install Mellanox plugin, follow these steps:

#. Install Fuel Master node. For more information on how to create a Fuel Master node, please see `Mirantis Fuel 8.0 documentation <https://docs.mirantis.com/openstack/fuel/fuel-8.0/>`_.
#. Download the plugin rpm file for MOS 8.0 from `Fuel Plugin Catalog <https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins>`_.
#. Copy the plugin on already installed Fuel Master. scp can be used for that.::

   # scp mellanox-plugin-3.2-3.2.0-1.noarch.rpm root@<Fuel_Master_ip>:/tmp

#. Install the plugin::

   # cd /tmp
   # fuel plugins --install mellanox-plugin-3.2-3.2.0-1.noarch.rpm

#. Verify the plugin was installed successfully by having it listed using ``fuel plugins`` command::

   # fuel plugins
   #  id | name              | version | package_version
   #  ---|-------------------|---------|----------------
   #  1  | mellanox-plugin   | 3.2.0   | 3.0.0

#. Define bootstrap discovery parameters to be burnt on Mellanox Adapters cards:

   - **link_type** , available link_type values are:

      - ``eth`` for changing link type to Ethernet
      - ``ib`` for changing link type to Infiniband
      - ``current`` for leaving link type as is

   - **max_num_vfs** as integer, default is set to 16.

#. Create Bootstrap discovery image for detecting Mellanox HW and support related configurations
   with pre-defined parameters::

   [root@fuel ~]# create_mellanox__bootstrap --link_type $link_type --max_num_vfs $max_num_vfs
   [root@fuel ~]# create_mellanox_bootstrap --help

 ::

   usage: create_mellanox_bootstrap [-h] [--link_type {eth,ib,current}]
                                 [--max_num_vfs MAX_NUM_VFS]
   Available link_type values are:
   -------------------------------
   - eth for changing link type to Ethernet
   - ib for changing link type to Infiniband
   - current for leaving link type as is

   optional arguments:
     -h, --help            show this help message and exit
     --link_type {eth,ib,current}
     --max_num_vfs MAX_NUM_VFS
                        an integer for the maximum number of vfs to be burned in bootstrap


   ::

     Try to build image with data:
     bootstrap:
     certs: null
     container: {format: tar.gz, meta_file: metadata.yaml}
     . . .
     . . .
     . . .
     Bootstrap image f790e9f8-5bc5-4e61-9935-0640f2eed949 has been activated.

#. Reboot nodes after installing plugin::

   [root@fuel ~]# reboot_bootstrap_nodes -a
   [root@fuel ~]# reboot_bootstrap_nodes -h

 ::

   Usage: reboot_bootstrap_nodes [-e environment_id] [-h] [-a]
      This script is used to trigger reboot for nodes in 'discover' status,
      of a given environment (if given) or of all environments.
      Please wait for nodes to boot again after triggering this script.

   Options:

   -h         Display the help message.
   -e <env>   Reboot all nodes in state 'discover' of the given environment.
   -a         Reboot all nodes in state 'discover' of all environments.


#. Create an environment - for more information please see `how to create an environment <https://docs.mirantis.com/openstack/fuel/fuel-8.0/user-guide.html>`_.
   We support both main network configurations:

   - `Neutron with VLAN segmentation`
   - `Neutron with tunneling segmentation`

   .. image:: ./_static/ml2_driver.png
   .. :alt: Network Configuration Type

#. Adjust the kernal parameters in the settings tab which is a condition for both iSER and SRIOV.
   Open the Settings tab, select General section and then add ``intel_iommu=on`` at the beginning of the initial parameters.

   .. image:: ./_static/kernal_parameters.png
   .. :alt: Hypervisor Type

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


   #. Support NEO SDN controller auto VLAN Provisioning (Neutron)
      **Note**: Relevant for `VLAN segmentation` only

      If selected, Mellanox NEO Mechanism driver will be used in order to support Auto switch VLAN auto-provisioning for Ethernet network

      To use this feature please provide IP address, username and password for NEO SDN controller.

      .. image:: ./_static/neo.png
      .. :alt: Enable NEO Driver mechanism support

      Additional info about NEO can be found by link: https://community.mellanox.com/docs/DOC-2155


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

#. When using SR-IOV you can set the number of virtual NICs (virtual functions) to up to 31
   if your hardware and system capabilities like memory and BIOS support it).
   In any case of SR-IOV hardware limitation, the installation will try to fallback a VF number to the default of 16 VFs.

