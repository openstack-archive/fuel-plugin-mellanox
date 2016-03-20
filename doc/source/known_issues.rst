Known issues
============

Issue 1
    - Description: This release supports Mellanox ConnectX®-3 family adapters only.
    - Workaround: NA

Issue 2
    - Description: For custom (OEM) adapter cards based on Mellanox ConnectX-3 / ConnectX-3 Pro ICs, adapter firmware must be manually burnt prior to the installation with SR-IOV support
    - Workaround: See `the firmware installation instructions <http://www.mellanox.com/page/oem_firmware_download>`_.

Issue 3
    - Description: The number of SR-IOV virtual functions supported by Mellanox adapters is up to 16 on ConnectX-3 adapters and up to 62 on ConnectX-3 Pro adapters (depends on your HW capabilities).
    - Workaround: NA

Issue 4
    - Description: Live and non-live migrations are not supported for VMs with SR-IOV port.
    - Workaround: NA

Issue 5
    - Description: When using a dual port physical NIC for SR-IOV over Ethernet, the Openstack private network has to be allocated on the first port.
    - Workaround: NA

Issue 6
    - Description: Deployments with Neo VLAN / PKEY provisioning might have delays in provisioning when the network is over Power PC switches.
    - Workaround: NA

Issue 7
    - Description: Network verification for IB network is not supported over untagged networks or after deployment.
    - Workaround: NA

Issue 8
    - Description: Starting large amount (>15) of IB PV VMs at once may result in some VMs not getting DHCP over InfiniBand networks.
    - Workaround: reboot VMs that didn.t get IP from DHCP on time or start VMs in smaller chunks (<10).

Issue 9
    - Description: SR-IOV Detach port / network from Qos-Policy is not working (https://bugs.launchpad.net/neutron/+bug/1504165).
    - Workaround: delete port / instance and attach a new port.

Issue 10
    - Description: Normal and Direct port ping on the same Hypervisor is not supported.
    - Workaround: Do not schedule Direct and Normal port of the same network on the same Hypervisor.
