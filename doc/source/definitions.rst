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

VXLAN offload
    Virtual Extensible LAN (VXLAN) is a network virtualization technology that attempts to improve the scalability problems associated with large cloud computing deployments

QoS
    QoS is defined as the ability to guarantee certain network requirements like bandwidth, latency, jitter and reliability in order to satisfy a Service Level Agreement (SLA) between an application provider and end users.

VF
    VF is virtual NIC that will be available for VMs on Compute nodes.

OpenSM
    OpenSM is an InfiniBand compliant Subnet Manager and Administration, and runs on top of OpenIB. It provides an implementation of an InfiniBand Subnet Manager and Administration. Such a software entity is required to run for in order to initialize the InfiniBand hardware (at least one per each InfiniBand subnet).

PKey
    PKEY stands for partition key. It is a 16 bit field within the InfiniBand header called BTH (Base Transport Header). A collection of endnodes with the same PKey in their PKey Tables are referred to as being members of a partition.

ConnectX-4
    `ConnectX-4 <http://www.mellanox.com/page/products_dyn?product_family=201&>`_ adapter cards with Virtual Protocol Interconnect (VPI), supporting EDR 100Gb/s InfiniBand and 100Gb/s Ethernet connectivity, provide the highest performance and most flexible solution for high-performance, Web 2.0, Cloud, data analytics, database, and storage platforms.

NEO
    Mellanox NEO™ is a powerful platform for managing scale-out computing networks. Mellanox NEO™ enables data center operators to efficiently provision, monitor and operate the modern data center fabric.
