.. raw:: pdf

    PageBreak

Known issues
============

Issue 1
    - Description: This release supports Mellanox ConnectX-3 family adapters only
    - Workaround: NA

Issue 2
    - Description: For custom (OEM) adapter cards based on Mellanox ConnectX-4 ICs, adapter firmware must be manually burnt prior to the installation with SR-IOV support
    - Workaround: See `the firmware installation instructions <http://www.mellanox.com/page/oem_firmware_download>`_.

Issue 3
    - Description: The number of SR-IOV virtual functions supported by Mellanox adapters is up to 31 on ConnectX-4 adapters (depends on your HW capabilities).
    - Workaround: NA

Issue 4
    - Description: Using an untagged storage network on the same interface with a private network over Ethernet is not supported when using iSER
    - Workaround: Use a separate interface for untagged storage networks for iSER over Ethernet or use a tagged storage network instead

Issue 5
    - Description: Recovering of a Cinder target might take more than 10 minutes in tagged storage network. 
    - Workaround: Ping from the Cinder target after the reboot to another machine in the cluster over the storage network. The VLAN storage network will be over vlan<vlan#> interface.
