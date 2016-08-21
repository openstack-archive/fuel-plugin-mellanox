#!/usr/bin/python
# Copyright 2016 Mellanox Technologies, Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys
import subprocess
import yaml
import glob
import logging
import traceback

MAX_NUM_VFS = 16
MLNX_SECTION = 'mellanox-plugin'
SETTINGS_FILE = '/etc/astute.yaml'
PLUGIN_OVERRIDE_FILE = '/etc/hiera/override/plugins.yaml'
MLNX_DRIVERS_LIST = { 'ConnectX-3': {'eth_driver' : 'mlx4_en', 'ib_driver' : 'eth_ipoib'},
                      'ConnectX-4': {'eth_driver' : 'mlx5_core', 'ib_driver' : 'eth_ipoib'}}
MLNX_DRIVERS = set([MLNX_DRIVERS_LIST[card][net]
                    for card in MLNX_DRIVERS_LIST
                    for net in MLNX_DRIVERS_LIST[card]])
ETH_DRIVERS = set([MLNX_DRIVERS_LIST[card][net]
                   for card in MLNX_DRIVERS_LIST
                   for net in MLNX_DRIVERS_LIST[card]
                   if net == 'eth_driver'])
IB_DRIVERS = MLNX_DRIVERS - ETH_DRIVERS
ISER_IFC_NAME = 'mlnx_iser0'
LOG_FILE = '/var/log/mellanox-plugin.log'

class MellanoxSettingsException(Exception):
    pass

class MellanoxSettings(object):

    data = None
    mlnx_interfaces_section = None

    @classmethod
    def get_mlnx_section(cls):
        if cls.data is None:
            raise MellanoxSettingsException("No YAML file loaded")
        if MLNX_SECTION not in cls.data:
            raise MellanoxSettingsException(
                "Couldn't find section '{0}'".format(MLNX_SECTION)
            )
        return cls.data[MLNX_SECTION]

    @classmethod
    def get_bridge_for_network(cls, network):
        network_to_bridge = {
            'private': 'prv',
            'management': 'mgmt',
            'storage': 'storage',
        }
        return 'br-{0}'.format(network_to_bridge[network])

    @classmethod
    def get_interface_by_network(cls, network):
        if network not in ('management', 'storage', 'private'):
           raise MellanoxSettingsException("Unknown network: {0}".format(network))
        mlnx_interfaces_section = cls.mlnx_interfaces_section
        ifc = mlnx_interfaces_section[network]['interface']
        return ifc

    @classmethod
    def get_card_type(cls, driver):
        for card in MLNX_DRIVERS_LIST.keys():
          if driver in MLNX_DRIVERS_LIST[card].values():
            network_driver_type = MLNX_DRIVERS_LIST[card].keys()[MLNX_DRIVERS_LIST[card].values()\
                                            .index(driver)]
            return card

    @classmethod
    def add_cx_card(cls):
        mlnx_interfaces = cls.mlnx_interfaces_section
        drivers = list()
        interfaces = list()
        mlnx = cls.get_mlnx_section()
        for network_type, ifc_dict in mlnx_interfaces.iteritems():
            if 'driver' in ifc_dict and network_type in ['private','management','storage']:
              
              # Here we handle the bond interfaces by extanding them to the list,
              # otherwise we append the interface to the list.
              if(type(ifc_dict['driver']) is list):
                  drivers.extend(ifc_dict['driver'])
              else:
                  drivers.append(ifc_dict['driver'])

              if(type(ifc_dict['interface']) is list):
                  interfaces.extend(ifc_dict['interface'])
              else:
                  interfaces.append(ifc_dict['interface'])

        drivers_set = list(set(drivers))
        interfaces_set = list(set(interfaces))

        if (len(drivers_set) > 1):
             logging.error("Multiple ConnectX adapters was found in this environment.")
             raise MellanoxSettingsException(
                 "Multiple ConnectX adapters was found in this environment."
             )
        else:
          current_driver = drivers_set[0]
          mellanox_interface = interfaces_set[0]
          if current_driver in ETH_DRIVERS:
              mlnx['network_type'] = 'ethernet'
              mlnx['cx_card'] = cls.get_card_type(current_driver)
          elif current_driver in IB_DRIVERS:
              mlnx['network_type'] = 'infiniband'
              ibdev = os.popen('ibdev2netdev').readlines()
              if not ibdev:
                mlnx['cx_card'] = 'none'
                logging.error('Failed executing ibdev2netdev')
                return 0
              interface_line = [l for l in ibdev if mellanox_interface in l]
              if interface_line and 'mlx5' in interface_line.pop():
                  mlnx['cx_card'] = 'ConnectX-4'
              else:
                  mlnx['cx_card'] = 'ConnectX-3'

          network_info_msg = 'Detected Network Type is: {0} '.format(mlnx['network_type'])
          card_info_msg = 'Detected Card Type is: {0} '.format(mlnx['cx_card'])
          logging.info(network_info_msg)
          logging.info(card_info_msg)

    @classmethod
    def add_driver(cls):
        interfaces = cls.get_interfaces_section()
        mlnx = cls.get_mlnx_section()
        drivers = cls.get_physical_interfaces()
        if len(drivers) > 1:
            raise MellanoxSettingsException(
                "Found mismatching Mellanox drivers on different interfaces: "
                "{0}".format(mlnx_drivers)
            )
        if len(drivers) == 0:
            raise MellanoxSettingsException(
                "\nNo Network role was assigned to Mellanox interfaces. "
                "\nPlease go to nodes tab in Fuel UI and reset your network "
                "roles in interfaces screen. aborting. "
            )
        mlnx['driver'] = drivers[0]

    @classmethod
    def add_physical_port(cls):
        interfaces = cls.get_interfaces_section()
        mlnx = cls.get_mlnx_section()

        private_ifc = cls.get_interface_by_network('private')
        if mlnx['driver'] == MLNX_DRIVERS_LIST[mlnx['cx_card']]['ib_driver']:
            if 'bus_info' not in interfaces[private_ifc]['vendor_specific']:
                raise MellanoxSettingsException(
                    "Couldn't find 'bus_info' for interface "
                    "{0}".format(private_ifc)
                )
            mlnx['physical_port'] = interfaces[private_ifc]['vendor_specific']['bus_info']
        elif mlnx['driver'] == MLNX_DRIVERS_LIST[mlnx['cx_card']]['eth_driver']:
            mlnx['physical_port'] = private_ifc

    @classmethod
    def add_storage_vlan(cls):
        mlnx = cls.get_mlnx_section()
        mlnx_interfaces_section = cls.mlnx_interfaces_section
        vlan = mlnx_interfaces_section['storage']['vlan']
        # Set storage vlan in mlnx section if vlan is used with iser
        if vlan:
            try:
                mlnx['storage_vlan'] = int(vlan)
            except ValueError:
                raise MellanoxSettingsException(
                    "Failed reading vlan for br-storage"
                )
            if mlnx['driver'] == MLNX_DRIVERS_LIST[mlnx['cx_card']]['ib_driver']:
                pkey = format((int(vlan) ^ 0x8000),'04x')
                mlnx['storage_pkey'] = pkey

    @classmethod
    def add_storage_parent(cls):
        mlnx = cls.get_mlnx_section()
        storage_ifc = cls.get_interface_by_network('storage')
        mlnx['storage_parent'] = storage_ifc

    @classmethod
    def add_iser_interface_name(cls):
        mlnx = cls.get_mlnx_section()
        storage_ifc = cls.get_interface_by_network('storage')
        if mlnx['driver'] == MLNX_DRIVERS_LIST[mlnx['cx_card']]['eth_driver']:
            mlnx['iser_ifc_name'] = ISER_IFC_NAME
        elif mlnx['driver'] == MLNX_DRIVERS_LIST[mlnx['cx_card']]['ib_driver']:
            interfaces = cls.get_interfaces_section()
            mlnx['iser_ifc_name'] = interfaces[storage_ifc]['vendor_specific']['bus_info']
        else:
            raise MellanoxSettingsException("Could not find 'driver' in "
                                            "{0} section".format(MLNX_SECTION))

    @classmethod
    def set_storage_networking_scheme(cls):
        endpoints = cls.get_endpoints_section()
        interfaces = cls.get_interfaces_section()
        transformations = cls.data['network_scheme']['transformations']
        mlnx = cls.get_mlnx_section()

        for transformation in transformations:
            if ('bridges' in transformation) and ('br-storage' in transformation['bridges']):
                transformations.remove(transformation)
            elif ('name' in transformation) and ('br-storage' == transformation['name']) \
                and ('action' in transformation) and ('add-br' == transformation['action']):
                transformations.remove(transformation)

        # Handle iSER interface with and w/o vlan tagging
        storage_vlan = mlnx.get('storage_vlan')
        storage_parent = cls.get_interface_by_network('storage')
        if storage_vlan and mlnx['driver'] == MLNX_DRIVERS_LIST[mlnx['cx_card']]['eth_driver']: # Use VLAN dev
            vlan_name = "{0}.{1}".format(ISER_IFC_NAME, storage_vlan)
            # Set storage rule to iSER interface vlan interface
            cls.data['network_scheme']['roles']['storage'] = vlan_name
            # Set iSER interface vlan interface
            transformations.append({
                'action': 'add-port',
                'name': vlan_name,
                'vlan_id': int(storage_vlan),
                'vlan_dev': ISER_IFC_NAME,
                'mtu': '1500'
            })
            endpoints[vlan_name] = (
                endpoints.pop('br-storage', {})
            )

        else:
            vlan_name = mlnx['iser_ifc_name']

            # Commented until fixing bug LP #1450420
            # Meanwhile using a workaround of configuring ib0
            # and changing to its child in post deployment
            #if storage_vlan: # IB child
            #    vlan_name = mlnx['iser_ifc_name'] = \
            #        "{0}.{1}".format(mlnx['iser_ifc_name'],
            #        mlnx['storage_pkey'])

            # Set storage rule to iSER port
            cls.data['network_scheme']['roles']['storage'] = \
                mlnx['iser_ifc_name']

            # Set iSER endpoint with br-storage parameters
            endpoints[mlnx['iser_ifc_name']] = (
                endpoints.pop('br-storage', {})
            )
            interfaces[mlnx['iser_ifc_name']] = {}

        # Set role
        for role,bridge in cls.data['network_scheme']['roles'].iteritems():
            if bridge == 'br-storage':
                cls.data['network_scheme']['roles'][role] = vlan_name
        # Clean
        if storage_vlan: \
            storage_parent = "{0}.{1}".format(storage_parent, storage_vlan)

        for transformation in transformations:
            if ('name' in transformation) and (transformation['name'] == storage_parent) \
                and ('bridge' in transformation) and (transformation['bridge'] == 'br-storage') \
                and ('action' in transformation) and (transformation['action'] == 'add-port'):
                transformations.remove(transformation)

        endpoints['br-storage'] = {'IP' : 'None'}

    @classmethod
    def get_endpoints_section(cls):
        return cls.data['network_scheme']['endpoints']

    @classmethod
    def get_physical_interfaces(cls):
        # the main change will be here because it reads phy_interfaces
        mlnx_interfaces = cls.mlnx_interfaces_section
        drivers = list()
        mlnx = cls.get_mlnx_section()
        for network_type, ifc_dict in mlnx_interfaces.iteritems():
            if 'driver' in ifc_dict and \
                ifc_dict['driver'] in MLNX_DRIVERS_LIST[mlnx['cx_card']].values():
                  drivers.append(ifc_dict['driver'])
        return list(set(drivers))

    @classmethod
    def get_interfaces_section(cls):
        return cls.data['network_scheme']['interfaces']

    @classmethod
    def is_iser_enabled(cls):
        return cls.get_mlnx_section()['iser']

    @classmethod
    def is_sriov_enabled(cls):
        return cls.get_mlnx_section()['sriov']

    @classmethod
    def is_vxlan_offloading_enabled(cls):
        return cls.get_mlnx_section()['vxlan_offloading']

    @classmethod
    def add_reboot_condition(cls):
        # if MAX_NUM_VF > default which is 16, reboot
        mlnx = cls.get_mlnx_section()
        mst_start = os.popen('mst start;').readlines()
        burned_num_vfs_list = list()
        devices = os.popen('mst status -v| grep pciconf | grep {0} | awk \'{{print $2}}\' '.format(
                            mlnx['cx_card'].replace("-",""))).readlines()
        if len(devices) > 0:
            for dev in devices:
                num = os.popen('mlxconfig -d {0} q | grep NUM_OF_VFS | awk \'{{print $2}}\' \
                                '.format(dev.rsplit()[0])).readlines()
                if len(num) > 0:
                    burned_num_vfs_list.append(num[0].rsplit()[0])
                else:
                    logging.error("Failed to grep NUM_OF_VFS from Mellanox card")
                    sys.exit(1)
            burned_num_vfs_set_list = list(set(burned_num_vfs_list))
            for burned_num_vfs in burned_num_vfs_set_list :
                if int(burned_num_vfs) < int(mlnx['num_of_vfs']) :
                    mlnx['reboot_required'] = True
                    logging.info('reboot_required is true as {0} is < {1}'.format(burned_num_vfs,
                                                                              mlnx['num_of_vfs']))
                    break;
        else:
            logging.error("There are no Mellanox devices with {0} card".format(mlnx['cx_card']))
            sys.exit(1)

    @classmethod
    def update_role_settings(cls):
        # detect ConnectX card
        cls.add_cx_card()
        # realize the driver in use (eth/ib)
        cls.add_driver()
        # decide the physical function for SR-IOV
        cls.add_physical_port()
        # set iSER parameters
        if cls.is_iser_enabled():
            cls.add_storage_parent()
            cls.add_storage_vlan()
            cls.add_iser_interface_name()
            cls.set_storage_networking_scheme()
        # fill reboot condition
        cls.add_reboot_condition()

    @classmethod
    def read_from_yaml(cls, settings_file):
        try:
            fd = open(settings_file, 'r')
        except IOError:
            raise MellanoxSettingsException("Given YAML file {0} doesn't "
                                            "exist".format(settings_file))
        try:
            data = yaml.load(fd)
        except yaml.YAMLError, exc:
            if hasattr(exc, 'problem_mark'):
                mark = exc.problem_mark
                raise MellanoxSettingsException(
                    "Faild parsing YAML file {0}: error position "
                    "({2},{3})".format(mark.line+1, mark.column+1)
                )
        finally:
            fd.close()
        cls.data = data
        cls.mlnx_interfaces_section = cls.get_mlnx_interfaces_section()

    @classmethod
    def write_to_yaml(cls, settings_file):
        # choose only the edited sections
        data = {}
        data['network_scheme'] = cls.data['network_scheme']
        data[MLNX_SECTION] = cls.data[MLNX_SECTION]
        # create containing adir
        try:
            settings_dir = os.path.dirname(settings_file)
            if not os.path.isdir(settings_dir):
                os.makedirs(settings_dir)
        except OSError:
            raise MellanoxSettingsException(
                "Failed creating directory: {0}".format(settings_dir)
            )
        try:
            fd = open(settings_file, 'w')
            yaml.dump(data, fd, default_flow_style=False)
        except IOError:
            raise MellanoxSettingsException("Failed writing changes to "
                                            "{0}".format(settings_file))
        finally:
            if fd:
                fd.close()

    @classmethod
    def update_settings(cls):
        # define input yaml file
        try:
            cls.read_from_yaml(SETTINGS_FILE)
            cls.update_role_settings()
            cls.write_to_yaml(PLUGIN_OVERRIDE_FILE)
        except MellanoxSettingsException, exc:
            error_msg = "Couldn't add Mellanox settings to " \
                            "{0}: {1}\n".format(SETTINGS_FILE, exc)
            sys.stderr.write(error_msg)
            logging.error(error_msg)
            raise MellanoxSettingsException("Failed updating one or more "
                                            "setting files")
    @classmethod
    def get_mlnx_interfaces_section(cls):
            transformations = cls.data['network_scheme']['transformations']
            interfaces = cls.data['network_scheme']['interfaces']
            dict_of_interfaces = {}

            # Map bonds to interfaces
            for transformation in transformations:
                if transformation['action'] == 'add-bond':

                    # Init bonds on the first bond
                    if 'bonds' not in cls.data:
                        cls.data['bonds'] = {}

                    # Init bond assumptions
                    all_drivers_equal = True
                    first = transformation['interfaces'][0]
                    driver = interfaces[first]['vendor_specific']['driver']

                    # Check if all bond drivers are the same
                    for interface in transformation['interfaces']:
                        new_driver = \
                            interfaces[interface]['vendor_specific']['driver']
                        if new_driver != driver:
                            all_drivers_equal = False

                    if all_drivers_equal:
                        bond_driver = driver
                    else:
                        bond_driver = None

                    cls.data['bonds'][transformation['name']] = \
                        {'interfaces' : transformation['interfaces'],
                         'driver'     : bond_driver}

            # Map networks to interfaces
            for transformation in transformations:
                if transformation['action'] == 'add-port' or \
                    transformation['action'] == 'add-bond':
                    if transformation['bridge'] == 'br-fw-admin':
                        network_type = 'admin'
                    elif transformation['bridge'] == 'br-ex':
                        network_type = 'public'
                    elif transformation['bridge'] == 'br-aux' or \
                        transformation['bridge'] == 'br-mesh':
                        network_type = 'private'
                    elif transformation['bridge'] == 'br-mgmt':
                        network_type = 'management'
                    elif transformation['bridge'] == 'br-storage':
                        network_type = 'storage'
                    elif transformation['bridge'] == 'br-baremetal':
                        network_type = 'baremetal'

                    network_interface = {}
                    network_interface['bridge'] = transformation['bridge']

                    # Split to iface name and VLAN
                    iface_split = transformation['name'].split('.')
                    if len(iface_split)==1:
                        iface_split.append(str(1))
                    interface, vlan = iface_split
                    network_interface['interface'] = interface
                    network_interface['vlan'] = vlan

                    # If bond
                    if 'bonds' in cls.data and interface in cls.data['bonds']:
                        network_interface['driver'] = \
                            cls.data['bonds'][interface]['driver']
                        if ( network_type == 'private' and cls.is_sriov_enabled() ) or \
                            ( network_type == 'storage' and cls.is_iser_enabled() ):
                            
                            # Assign SR-IOV/ISER to the first port only.
                            # This is a temporary workaround until supporing bond over VFs.
                            # We sort the array of interfaces in order to get the first
                            # interface on all nodes.
                            if_list=cls.data['bonds'][interface]['interfaces']
                            if_list.sort()
                            network_interface['interface'] = if_list[0]
                    else: # Not a bond
                        network_interface['driver'] = \
                            interfaces[interface]['vendor_specific']['driver']
                    dict_of_interfaces[network_type] = network_interface

            # Set private network in case private and storage on the same port
            if 'private' not in dict_of_interfaces.keys() and \
                'storage' in dict_of_interfaces.keys():
                dict_of_interfaces['private'] = dict_of_interfaces['storage']
                dict_of_interfaces['private']['bridge'] = 'br-prv'
            return dict_of_interfaces

def main():
    logging.basicConfig(format='%(asctime)s %(message)s',
                        level=logging.DEBUG, filename=LOG_FILE)

    try:
        settings = MellanoxSettings()
        settings.update_settings()
    except MellanoxSettingsException, exc:
        error_msg = "Failed adding Mellanox settings: {0}\n".format(exc)
        sys.stderr.write(error_msg)
        logging.error(exc)
        sys.exit(1)
    success_msg = "Done adding Mellanox settings\n"
    sys.stdout.write(success_msg)
    logging.info(success_msg)
    sys.exit(0)

if __name__ == '__main__':
    main()
