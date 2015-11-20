.. _known_issues:


Known issues
============

Issue 1
    - Description: This release supports Mellanox ConnectX®-3 family adapters only.
    - Workaround: NA

Issue 2
    - Description: For custom (OEM) adapter cards based on Mellanox ConnectX-3 / ConnectX-3 Pro ICs, adapter firmware must be manually burnt prior to the installation with SR-IOV support
    - Workaround: See `the firmware installation instructions <http://www.mellanox.com/page/oem_firmware_download>`_.

Issue 3
    - Description: The number of SR-IOV virtual functions supported by Mellanox adapters is 16 on ConnectX-3 adapters and 128 on ConnectX-3 Pro adapters.
    - Workaround: NA

Issue 4
    - Description: Deploying more than 10 nodes at a time over a slow PXE network can cause timeouts during the OFED installation
    - Workaround: Deploy chunks of up to 10 nodes or increase the delay-before-timeout in the plugin’s tasks.yaml file on the Fuel master node. If timeout occurs, click **Deploy Changes** button again.


Issue 5
    - Description: Using an untagged storage network on the same interface with a private network over Ethernet is not supported when using iSER.
    - Workaround: Use a separate interface for untagged storage networks for iSER over Ethernet or use a tagged storage network instead.

Issue 6
    - Description: Recovering of a Cinder target might take more than 10 minutes in tagged storage network.
    - Workaround: Ping from the Cinder target after the reboot to another machine in the cluster over the storage network. The VLAN storage network will be over vlan<vlan#> interface.


