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
import yaml
import glob
import logging
import traceback

MLNX_SECTION = 'mellanox-plugin'
SETTINGS_FILE = '/etc/astute.yaml'
PLUGIN_OVERRIDE_FILE = '/etc/hiera/override/plugins.yaml'
MLNX_DRIVERS_LIST = ('mlx4_en', 'eth_ipoib')
ISER_IFC_NAME = 'eth_iser0'
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
        if mlnx['driver'] == 'eth_ipoib':
            if 'bus_info' not in interfaces[private_ifc]['vendor_specific']:
                raise MellanoxSettingsException(
                    "Couldn't find 'bus_info' for interface "
                    "{0}".format(private_ifc)
                )
            mlnx['physical_port'] = interfaces[private_ifc]['vendor_specific']['bus_info']
        elif mlnx['driver'] == 'mlx4_en':
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
            if mlnx['driver'] == 'eth_ipoib':
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
        if mlnx['driver'] == 'mlx4_en':
            mlnx['iser_ifc_name'] = ISER_IFC_NAME
        elif mlnx['driver'] == 'eth_ipoib':
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

        transformations.remove({
            'action': 'add-br',
            'name': 'br-storage'
        })
        for transforamtion in transformations:
            if ('bridges' in transforamtion) and ('br-storage' in transforamtion['bridges']):
                transformations.remove(transforamtion)

        # Handle iSER interface with and w/o vlan tagging
        storage_vlan = mlnx.get('storage_vlan')
        storage_parent = cls.get_interface_by_network('storage')
        if storage_vlan and mlnx['driver'] == 'mlx4_en': # Use VLAN dev
            vlan_name = "{0}{1}".format('vlan', storage_vlan)
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
        transformations.remove({
            'action': 'add-port',
            'bridge': 'br-storage',
            'name': storage_parent,
        })
        endpoints['br-storage'] = {'IP' : 'None'}

    @classmethod
    def get_endpoints_section(cls):
        return cls.data['network_scheme']['endpoints']

    @classmethod
    def get_physical_interfaces(cls):
        # the main change will be here because it reads phy_interfaces
        mlnx_interfaces = cls.mlnx_interfaces_section
        drivers = list()
        for network_type, ifc_dict in mlnx_interfaces.iteritems():
            if 'driver' in ifc_dict and \
                ifc_dict['driver'] in MLNX_DRIVERS_LIST:
                  drivers.append(ifc_dict['driver'])
        return list(set(drivers))

    @classmethod
    def get_interfaces_section(cls):
        return cls.data['network_scheme']['interfaces']

    @classmethod
    def is_iser_enabled(cls):
        return cls.get_mlnx_section()['iser']

    @classmethod
    def is_vxlan_offloading_enabled(cls):
        return cls.get_mlnx_section()['vxlan_offloading']

    @classmethod
    def update_role_settings(cls):
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
                        if network_type == 'private':

                            # Assign SR-IOV to the first port only
                            network_interface['interface'] = \
                                cls.data['bonds'][interface]['interfaces'][0]
                        else:
                            network_interface['interface'] = \
                                cls.data['bonds'][interface]['interfaces']
                    else: # Not a bond
                        network_interface['driver'] = \
                            interfaces[interface]['vendor_specific']['driver']
                    dict_of_interfaces[network_type] = network_interface
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
