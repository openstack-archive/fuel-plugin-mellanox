# mellanox_openstack

## Overview

The mellanox_openstack module is designated for configuring the Mellanox plugin
for openstack installed using Fuel.


## Module Description

This module was written for integrating Mellanox into Fuel (https://launchpad.net/fuel).
It configures the ml2 to work with Mellanox plugin, and installs and configures the environment.
SR-IOV for networking and iSER protocol for storage over Mellanox hardware are supported in this plugin.

### Setup Requirements

The module is designed to be used by Fuel (an openstack installer by Mirantis).
It assumes an Openstack environment using Neutron with VLAN segmentation & KVM.


## Release Notes/Contributors/Etc

Contributors:
Gil Meir, gilmeir@mellanox.com
Aviram Bar-Haim, aviramb@mellanox.com

Support:
Mellanox support - support@mellanox.com
