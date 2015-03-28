#!/usr/bin/python

import os
import sys
import yaml
import glob
import traceback

ROLES = ['primary-controller', 'controller', 'compute', 'cinder']
MLNX_SECTION = 'mellanox_plugin'
MLNX_DRIVERS_LIST = ('mlx4_en', 'eth_ipoib')
ISER_IFC_NAME = 'eth_iser0'


class MellanoxSettingsException(Exception):
    pass

class MellanoxSettings(object):

    data = None

    @classmethod
    def get_node_roles(cls):
        node_roles = {}
        for f in glob.glob('/etc/*.yaml'):
            role = os.path.splitext(os.path.basename(f))[0]
            if role in ROLES:
                node_roles[role] = f
        if not node_roles:
            sys.stdout.write("This node wasn't set to any of these roles: "
                             "{0}".format(ROLES))
        return node_roles

    @classmethod
    def get_mlnx_section(cls):
        if cls.data is None:
            raise MellanoxSettingsException("No YAML file loaded")
        if MLNX_SECTION not in cls.data:
            raise MellanoxSettingsException(
                "Couldn't find section '{0}' in '{1}' role "
                "settings file".format(MLNX_SECTION, cls.role)
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
        try:
            vlan = int(endpoints['br-storage']['vendor_specific']['vlans'])
        except ValueError:
            raise MellanoxSettingsException(
                "Failed reading vlan for br-storage"
            )
        mlnx['storage_vlan'] = vlan

    @classmethod
    def add_storage_parent(cls):
        mlnx = cls.get_mlnx_section()
        storage_ifc = cls.get_interface_by_network('storage')
        mlnx['storage_parent'] = storage_ifc

    @classmethod
    def add_iser_interface_name(cls):
        mlnx = cls.get_mlnx_section()
        storage_ifc = cls.get_interface_by_network('storage')
        if mlnx['driver'] == 'eth_ipoib':
            mlnx['iser_ifc_name'] = interfaces[storage_ifc]['vendor_specific']['bus_info']
        elif mlnx['driver'] == 'mlx4_en':
            mlnx['iser_ifc_name'] = ISER_IFC_NAME
        else:
            raise MellanoxSettingsException("Could not find 'driver' in mellanox_plugin section")

    @classmethod
    def set_storage_networking_scheme(cls):
        endpoints = cls.get_endpoints_section()
        interfaces = cls.get_interfaces_section()
        transformations = cls.data['network_scheme']['transformations']
        mlnx = cls.get_mlnx_section()

        storage_vlan = mlnx['storage_vlan']
        if storage_vlan:
            vlan_name = "{0}.{1}".format(ISER_IFC_NAME, storage_vlan)
            # Set storage rule to iSER interface vlan interface
            cls.data['network_scheme']['roles']['storage'] = vlan_name
            # Set iSER interface vlan interface
            #interfaces[vlan_name] = {}
            transf_add = {
                'action': 'add-port',
                'name': vlan_name,
                'vlan_id': int(storage_vlan),
                'vlan_dev': ISER_IFC_NAME
            }
            if transf_add not in transformations:
                transformations.append(transf_add)
            transformations_to_delete = [
                { 'action': 'add-port',
                  'name': "{0}.{1}".format(
                      cls.get_interface_by_network('storage'),
                      storage_vlan
                   ),
                  'bridge': 'br-storage' } ,
                { 'action': 'add-br',
                  'name': 'br-storage' }
            ]
            endpoints['br-storage']['vendor_specific']['phy_interfaces'] = [ ISER_IFC_NAME ]
            endpoints[vlan_name] = (
                endpoints.pop('br-storage', {})
            )
            for transf_del in transformations_to_delete:
                transformations.remove(transf_del)
        else:
            # Set storage rule to iSER port
            cls.data['network_scheme']['roles']['storage'] = ISER_IFC_NAME
            # Set iSER endpoint with br-storage parameters
            endpoints[ISER_IFC_NAME] = (
                endpoints.pop('br-storage', {})
            )
            interfaces[ISER_IFC_NAME] = {}

    @classmethod
    def update_settings(cls):
        # select one role for this node
        roles = cls.get_node_roles()
        role = sorted(roles.keys()).pop()

        # define input and output yaml files
        settings_file = '/etc/{0}.yaml'.format(role)
        common_file = '/etc/hiera/override/common.yaml'
        try:
            cls.read_from_yaml(settings_file)
            cls.update_role_settings()
            cls.write_to_yaml(common_file)
        except MellanoxSettingsException, exc:
            sys.stderr.write("Couldn't add Mellanox settings to "
                                 "{0}: {1}\n".format(settings_file, exc))
            raise MellanoxSettingsException("Failed updating one or more "
                                            "setting files")

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
    def update_role_settings(cls):
        cls.add_driver()
        cls.add_physical_port()
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
        data['mellanox_plugin'] = cls.data['mellanox_plugin']
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
            fd.close()

    @classmethod
    def add_missing_sections(cls):
        for ifc in cls.data['network_scheme']['interfaces']:
            if ifc=='eth0':
                cls.data['network_scheme']['interfaces'][ifc]['driver'] = 'igb'
                cls.data['network_scheme']['interfaces'][ifc]['bus_info'] = '01:00.0'
            elif ifc=='eth1':
                cls.data['network_scheme']['interfaces'][ifc]['driver'] = 'igb'
                cls.data['network_scheme']['interfaces'][ifc]['bus_info'] = '01:00.1'
            elif ifc in ('eth2', 'eth3'):
                cls.data['network_scheme']['interfaces'][ifc]['bus_info'] = '03:00.0'
                cls.data['network_scheme']['interfaces'][ifc]['driver'] = 'mlx4_en'

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
