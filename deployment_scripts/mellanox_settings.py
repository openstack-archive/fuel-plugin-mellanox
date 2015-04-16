#!/usr/bin/python
# Copyright 2015 Mellanox Technologies, Ltd
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
import traceback

MLNX_SECTION = 'mellanox-plugin'
SETTINGS_FILE = '/etc/astute.yaml'
PLUGIN_OVERRIDE_FILE = '/etc/hiera/override/plugins.yaml'
MLNX_DRIVERS_LIST = ('mlx4_en', 'eth_ipoib')
ISER_IFC_NAME = 'eth_iser0'


class MellanoxSettingsException(Exception):
    pass

class MellanoxSettings(object):

    data = None

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
        br_name = cls.get_bridge_for_network(network)
        endpoints = cls.get_endpoints_section()
        ifc = endpoints[br_name]['vendor_specific']['phy_interfaces'][0]
        return ifc

    @classmethod
    def add_driver(cls):
        interfaces = cls.get_interfaces_section()
        mlnx = cls.get_mlnx_section()

        # validation that no more than 1 mellanox driver is used
        interfaces_drivers = {}
        for ifc in cls.get_physical_interfaces():
            if ('driver' not in interfaces[ifc]['vendor_specific']) :
                raise MellanoxSettingsException(
                    "Couldn't find 'driver' for interface '{0}'".format(ifc)
                )
            interfaces_drivers[ifc] = interfaces[ifc]['vendor_specific']['driver']
        mlnx_drivers = dict(
            (ifc, drv) for (ifc, drv) in interfaces_drivers.iteritems()
            if drv in MLNX_DRIVERS_LIST
        )
        if len(set(mlnx_drivers.values())) > 1:
            raise MellanoxSettingsException(
                "Found mismatching Mellanox drivers on different interfaces: "
                "{0}".format(mlnx_drivers)
            )

        # add the driver to the yaml
        mlnx['driver'] = mlnx_drivers.values().pop()

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
        endpoints = cls.get_endpoints_section()
        vlan = endpoints['br-storage']['vendor_specific'].get('vlans')
        # set storage vlan in mlnx section if vlan is used with iser
        if vlan:
            try:
                mlnx['storage_vlan'] = int(vlan)
            except ValueError:
                raise MellanoxSettingsException(
                    "Failed reading vlan for br-storage"
                )
            if mlnx['driver'] == 'eth_ipoib':
                pkey = format((vlan ^ 0x8000),'04x')
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
        br_prv_br_storage_patch = {
            'action': 'add-patch',
            'provider': 'ovs',
            'bridges': [
                'br-prv',
                'br-storage',
            ],
        }
        if br_prv_br_storage_patch in transformations:
            transformations.remove(br_prv_br_storage_patch)

        # Handle iSER interface with and w/o vlan tagging
        storage_vlan = mlnx.get('storage_vlan')
        storage_parent = cls.get_interface_by_network('storage')
        if storage_vlan and mlnx['driver'] == 'mlx4_en': # Use VLAN dev
            vlan_name = "{0}.{1}".format(ISER_IFC_NAME, storage_vlan)
            # Set storage rule to iSER interface vlan interface
            cls.data['network_scheme']['roles']['storage'] = vlan_name
            # Set iSER interface vlan interface
            transformations.append({
                'action': 'add-port',
                'name': vlan_name,
                'vlan_id': int(storage_vlan),
                'vlan_dev': ISER_IFC_NAME
            })
            endpoints['br-storage']['vendor_specific']['phy_interfaces'] = [ ISER_IFC_NAME ]
            endpoints[vlan_name] = (
                endpoints.pop('br-storage', {})
            )
        else:
            # Set storage rule to iSER port
            cls.data['network_scheme']['roles']['storage'] = \
                mlnx['iser_ifc_name']

            # Set iSER endpoint with br-storage parameters
            endpoints[mlnx['iser_ifc_name']] = (
                endpoints.pop('br-storage', {})
            )
            interfaces[mlnx['iser_ifc_name']] = {}

        if storage_vlan: \
            storage_parent = "{0}.{1}".format(storage_parent, storage_vlan)
        transformations.remove({
            'action': 'add-port',
            'bridge': 'br-storage',
            'name': storage_parent,
        })

    @classmethod
    def get_endpoints_section(cls):
        return cls.data['network_scheme']['endpoints']

    @classmethod
    def get_physical_interfaces(cls):
        endpoints = cls.get_endpoints_section()
        interfaces = cls.get_interfaces_section()
        mlnx_phys_ifcs = []
        for ep in endpoints:
            # skip non physical interfaces
            if ('vendor_specific' not in endpoints[ep] or
                    'phy_interfaces' not in endpoints[ep]['vendor_specific']):
                continue
            phys_ifc = endpoints[ep]['vendor_specific']['phy_interfaces'][0]
            if ('vendor_specific' not in interfaces[phys_ifc] or
                    'driver' not in interfaces[phys_ifc]['vendor_specific']):
                raise MellanoxSettingsException(
                    "Missing 'vendor_specific' or 'driver' "
                    "in {0}".format(phys_ifc)
                )
            if (interfaces[phys_ifc]['vendor_specific']['driver'] in
                    MLNX_DRIVERS_LIST):
                mlnx_phys_ifcs.append(phys_ifc)
        return list(set(mlnx_phys_ifcs))

    @classmethod
    def get_interfaces_section(cls):
        return cls.data['network_scheme']['interfaces']

    @classmethod
    def is_iser_enabled(cls):
        return cls.get_mlnx_section()['iser']

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
            sys.stderr.write("Couldn't add Mellanox settings to "
                             "{0}: {1}\n".format(settings_file, exc))
            raise MellanoxSettingsException("Failed updating one or more "
                                            "setting files")

def main():
    try:
        settings = MellanoxSettings()
        settings.update_settings()
    except MellanoxSettingsException, exc:
        sys.stderr.write("Failed adding Mellanox settings: {0}\n".format(exc))
        sys.exit(1)
    except Exception, exc:
        sys.stderr.write("An unknown error has occured while adding "
                         "Mellanox settings: {0}\n".format(
                             traceback.format_exc()
                         )
        )
        sys.exit(1)
    sys.stdout.write("Done adding Mellanox settings\n")
    sys.exit(0)

if __name__ == '__main__':
    main()
