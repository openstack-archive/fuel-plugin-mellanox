..
 This work is licensed under the Apache License, Version 2.0.

 http://www.apache.org/licenses/LICENSE-2.0

=============================
Mellanox Fuel plugin
=============================

In Fuel 5.1, support for Mellanox high performance Ethernet virtualization
and storage features has been added.

Starting with version 6.0, Fuel supports a Pluggable architecture.

Mellanox Fuel plugin adds support for Mellanox high performance
features for Mirantis Opesntack, over Ethernet and Infiniband networks,
built using ConnectX-3 family Adapters.

Mellanox high performance features are currently includes Mellanox SR-IOV
mechanism driver for neutron ML2 plugin and RDMA extension for iSCSI (iSER)
in Cinder.

Problem description
===================

Fuel Supports Mellanox features for Ethernet only in a non pluggable approach.

Proposed change
===============

Implement a Fuel plugin that will install and configure Mellanox high
performance features, upon user request, over Ethernet and Infinband networks.

Alternatives
------------

It might have been implemented as part of Fuel core but we decided to make it
as a plugin for several reasons:

* This isn't something that all operators may want to deploy.
* Any new additional functionality makes the project's testing more difficult,
  which is an additional risk for the Fuel release.

Data model impact
-----------------

None

REST API impact
---------------

None

Upgrade impact
--------------

None

Security impact
---------------

None

Notifications impact
--------------------

None

Other end user impact
---------------------

None

Performance Impact
------------------

Installing Mirantis Openstack over Mellanox ConnectX-3 family Adapters,
increases the cluster performance dramatically,
and enables RDMA (Remote direct memory access) between virtual machines
and in storage initiators to targets.

Other deployer impact
---------------------

None

Developer impact
----------------

None

Implementation
==============

The plugin delivers official Mellanox Openstack packages, in order to enable
Neutron SR-IOV and Cinder iSER high performance features.
This plugin replaces the bootstrap image, in order to transparently discover
the nodes hardware, over Ethernet and Infiniband networks.
This Plugin has several tasks:

* Start Mellanox plugin log.
* Update the configurations yaml to include mellanox plugin settings,
  that has been chosen by the user.
* Verify that kernel devel packages are installed and install the relevant
  MLNX_OFED packages, for using Ethernet/Infiniband network over Mellanox
  hardware.
* Enable SR-IOV settings, if neutron has been chosen to use SR-IOV.
* Establish a special interface for storage network, that supports RDMA,
  if iSER has been chosen.
* Deploy puppets for Controller, Compute and Cinder roles, with the relevant
  changes needed for iSER / SR-IOV (in case of using each).
* Replace the glance cirros image with an image that supports SR-IOV (in case
  of using SR-IOV).

Assignee(s)
-----------

| David Slama <dudus@mellanox.com> (PM)
| Aviram Bar-Haim <aviramb@mellanox.com> (Release manager)
| Andrey Yevsyukov <andreyy@mellanox.com> (Developer)
| Gil Meir <gmeir11@gmail.com> (Developer)
| Amichay Polishuk <amichayp@mellanox.com> (QA engineer)
| Noam Angel <amichayp@mellanox.com> (QA engineer)
| Lenny Verkhovsky <lennyb@mellanox.com> (Verification engineer)
| Rawan Herzallah <rherzallah@asaltech.com> (Verification engineer)
| Murad Awawdeh <mawawdeh@asaltech.com> (Verification engineer)

Work Items
----------

* Implement the Fuel plugin.
* Implement the Puppet manifests.
* Testing (CI verification and QA automatic and manual tests).
* Write the documentation.

Dependencies
============

* Fuel 6.1 and higher.

Testing
=======

* Prepare a test plan.
* Test the plugin by deploying environments with all relevant Fuel deployment
  modes.
* Test extensive cases for SR-IOV and iSER features over Ethernet and
  Infiniband networks.

Documentation Impact
====================

* Deployment Guide (how to install the plugin, how to configure and deploy an
  OpenStack environment with the plugin).
* User Guide (which features the plugin provides, how to use them in the
  deployed OpenStack environment).
* Test Plan.
* Test Report.

References
==========

* `HowTo Install Mellanox OpenStack Plugin for Mirantis Fuel 6.1
  <https://community.mellanox.com/docs/DOC-2165>`_
