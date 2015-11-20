.. fuel-plugin-mellanox documentation master file, created by
   sphinx-quickstart on Wed Oct  7 12:48:35 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

======================================================
Guide to the Mellanox Plugin ver. 2.0-2.0.0-2 for Fuel
======================================================

User documentation
==================

.. toctree::
   :maxdepth: 2
 
   overview
   installation
   guide
   known issues
   supported images
   appendix

Definitions, Acronyms and abbreviations
=======================================

SR-IOV
    SR-IOV stands for "Single Root I/O Virtualization". It is a specification that allows a PCI device to appear virtually in multiple virtual machines (VMs), each of which has its own virtual function. The specification defines virtual functions (VFs) for the VMs and a physical function for the hypervisor. Using SR-IOV in a cloud infrastructure helps reaching higher performance since traffic bypasses the TCP/IP stack in the kernel.

iSER
    iSER stands for "iSCSI Extensions for RDMA". It is an extension of the data transfer model of iSCSI, a storage networking standard for TCP/IP. iSER enables the iSCSI protocol to take advantage of the RDMA protocol suite to supply higher bandwidth for block storage transfers (zero time copy behavior). To that fact, it eliminates the TCP/IP processing overhead while preserving the compatibility with iSCSI protocol.

RDMA
    RDMA stands for "Remote Direct Memory Access". It is a technology that enables to read and write data from remote server without involving the CPU. It reduces latency and increases throughput. In addition, the CPU is free to perform other tasks.

ConnectX-3 Pro
    `ConnectX-3 Pro <http://www.mellanox.com/page/products_dyn?product_family=119&mtag=connectx_3_vpi>`_ adapter cards with Virtual Protocol Interconnect (VPI) supporting InfiniBand and Ethernet connectivity provide the highest performing and most flexible interconnect solution for PCI Express Gen3 servers used in Enterprise Data Centers, High-Performance Computing, and Embedded environments.

Infiniband
    A computer-networking communications standard used in high-performance computing, features very high throughput and very low latency. It is used for data interconnect both among and within computers. InfiniBand is also utilized as either a direct, or switched interconnect between servers and storage systems, as well as an interconnect between storage systems.
