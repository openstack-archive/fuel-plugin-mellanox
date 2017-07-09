.. raw:: pdf

    PageBreak

Known issues
============

Issue 1
    - Description: For custom (OEM) adapter cards based on Mellanox ConnectX-5 ICs, adapter firmware must be manually burnt prior to the installation with SR-IOV support
    - Workaround: See `the firmware installation instructions <http://www.mellanox.com/page/oem_firmware_download>`_.

Issue 2
    - Description: The number of SR-IOV virtual functions supported by Mellanox adapters is up to 31 on ConnectX-5 adapters (depends on your HW capabilities).
    - Workaround: NA

Issue 3
    - Description: When using a dual port physical NIC for SR-IOV over Ethernet, the Openstack private network has to be allocated on the first port.
    - Workaround: NA

Issue 4
    - Description: Changing port type in bootstrap stage over a single port HCA is not supported
    - Workaround:  Create a bootstrap image with link type current, and change the port type manually.

Issue 5
    - Description: Starting large amount (>15) of IB VMs with normal port at once may result in some VMs not getting DHCP over InfiniBand networks.
    - Workaround: Reboot VMs that didn't get IP from DHCP on time or start VMs in smaller chunks (<10).

Issue 6
    - Description: Network verification for IB network is not supported over untagged networks or after deployment.
    - Workaround: NA

Issue 7
    - Description: When using NEO auto provisioning, network verification should fail for the private network VLANs
    - Workaround: NA

Issue 8
    - Description: When deploying an Infiniband cluster with iSER over VLAN, all controllers should be deployed at once.
    - Workaround: Use untagged storage network when using Infiniband with iSER over VLAN, or deploy all controllers at once.
