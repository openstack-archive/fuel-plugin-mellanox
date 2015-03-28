# mellanox_openstack

## Overview

The mellanox_openstack module is designated for configuring the Mellanox plugin
for openstack installed using Fuel.


## Module Description

This module was written for integrating Mellanox into Fuel (https://launchpad.net/fuel).
The plugin supports SR-IOV for networking and iSER protocol for storage features over Mellanox hardware.
* SR-IOV - ml2 is configured to work with Mellanox plugin, including Eswitchd service
  for managing virtual functions, and Mellanox Neutron Agent for networking properties.
* iSER - Cinder is set to work with iSER protocol.


### Setup Requirements

The module is designed to be used by Fuel (an openstack installer by Mirantis).
It assumes an Openstack environment using Neutron with VLAN segmentation & KVM.


## Release Notes/Contributors/Etc

Contributors:
Gil Meir, gilmeir@mellanox.com
Aviram Bar-Haim, aviramb@mellanox.com

Support:
Mellanox support - support@mellanox.com
