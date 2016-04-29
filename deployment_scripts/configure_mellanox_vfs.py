#!/usr/bin/env python
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
import logging
import traceback
import glob

LOG_FILE = '/var/log/mellanox-plugin.log'

class MellanoxVfsSettingsException(Exception):
    pass

class MellanoxVfsSettings(object):

    mellanox_vfs = list();

    @classmethod
    def get_pci_list(cls):
        cmd_vfs = "lspci -D | grep -i mellanox | grep -i virtual | awk '{print $1}'"
        p_lspci = subprocess.Popen(cmd_vfs, shell=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT)
        retval = p_lspci.wait()
        if retval != 0:
            print 'Failed to execute command lspci.'
            logging.error("Failed to find mellanox VFs.")
            sys.exit(1)
        pci_res = list()
        for line in p_lspci.stdout.readlines():
            pci_res.append(line.rstrip())
        return pci_res

    @classmethod
    def build_vfs_dict(cls):
        pci_res = cls.get_pci_list()

        cmd_install_gawk = "apt-get -y install gawk"
        p_cmd_install_gawk = subprocess.Popen(cmd_install_gawk, shell=True, stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT)
        retval = p_cmd_install_gawk.wait()
        if retval != 0:
            print 'Failed to install gawk.'
            sys.exit(1)

        cmd_vfs_data = "ibdev2netdev -v"
        p_vfs_data = subprocess.Popen(cmd_vfs_data, shell=True, stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT)
        retval = p_vfs_data.wait()
        if retval != 0:
            print 'Failed to execute command ibdev2netdev -v.'
            logging.error("Failed to execute ibdev2netdev -v")
            sys.exit(1)

        ibdev = list()
        for vf_data in p_vfs_data.stdout.readlines():
            ibdev.append(vf_data.rstrip())

        cmd_vfs_macs = "ip link show | grep vf | awk '{print $4}' | tr -d ','"
        p_vfs_macs = subprocess.Popen(cmd_vfs_macs, shell=True, stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT)
        retval = p_vfs_macs.wait()
        if retval != 0:
            print 'Failed to execute command ip link show | grep vf '
            logging.error("Failed to find VFs in ip link show command")
            sys.exit(1)

        mac_list = list()
        for mac in p_vfs_macs.stdout.readlines():
            mac_list.append(mac.rstrip())

        count = 0
        for pci_address in pci_res:
            vf_dict = dict();
            vf_info = next((vf_info for vf_info in ibdev if pci_address in vf_info), None)
            vf_info = vf_info.split();
            vf_dict['vf_num'] = count;
            vf_dict['pci_address'] = vf_info[0]
            vf_dict['port_module'] = vf_info[1]
            vf_dict['port_num'] = vf_info[12]
            vf_dict['mac'] = mac_list[count]
            cls.mellanox_vfs.append(vf_dict)
            count += 1;

    @classmethod
    def unbind(cls):
        for vf in cls.mellanox_vfs:
            cmd_vfs_pci = "echo {0} ".format(vf['pci_address']) + \
                           ">> /sys/bus/pci/drivers/mlx5_core/unbind"
            p_unbind_pci = subprocess.Popen(cmd_vfs_pci, shell=True, stdout=subprocess.PIPE,
                                            stderr=subprocess.STDOUT)
            retval = p_unbind_pci.wait()
            if retval != 0:
                print 'Failed to unbind pci address ', vf['pci_address']
                logging.error("Failed to unbind pci address {0}".format(vf['pci_address']))
                sys.exit(1)
        logging.info("Managed to unbind VFs.")

    @classmethod
    def bind(cls):
        for vf in cls.mellanox_vfs:
            cmd_vfs_pci = "echo {0} ".format(vf['pci_address']) + \
                           ">> /sys/bus/pci/drivers/mlx5_core/bind"
            p_unbind_pci = subprocess.Popen(cmd_vfs_pci, shell=True, stdout=subprocess.PIPE,
                                            stderr=subprocess.STDOUT)
            retval = p_unbind_pci.wait()
            if retval != 0:
                print 'Failed to bind pci address ', vf['pci_address']
                logging.error("Failed to bind pci address {0}".format(vf['pci_address']) )
                sys.exit(1)
        logging.info("Managed to bind VFs.")

    @classmethod
    def assign_mac_per_vf(cls):
        for vf in cls.mellanox_vfs and "00:00:00:00:00:00" in vf['mac']:
            cmd_generate_mac = "ibstat {0} {1} |".format(vf['port_module'], vf['port_num']) + \
                               " grep GUID | cut -d' ' -f3 | cut -d'x' -f2"
            p_cmd_generate_mac = subprocess.Popen(cmd_generate_mac, shell=True,
                                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            retval = p_cmd_generate_mac.wait()
            if retval != 0:
                 print 'Failed to get ibstat port guid'
                 logging.error("Failed to find PORT GUID to set it as a MAC address for the VF")
                 sys.exit(1)
            port_guid = p_cmd_generate_mac.stdout.readlines()[0].rstrip();
            port_guid_to_mac = port_guid[0:12]
            port_guid_to_mac = ':'.join(port_guid_to_mac[i:i+2] for i in range \
                               (0, len(port_guid_to_mac), 2))
            vf['mac'] = port_guid_to_mac

    @classmethod
    def set_mac_per_vf(cls):
        cmd_physical_port = "hiera mellanox-plugin | grep physical_port | cut -d'>' -f2 "
        p = subprocess.Popen(cmd_physical_port ,shell=True,stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        physical_port = p.stdout.readlines()[0].rstrip()
        physical_port = physical_port.strip(',"')
        for vf in cls.mellanox_vfs:
            cmd_set_mac_per_vf = "ip link set " + \
                                 "{0} vf {1} mac {2}".format(physical_port,vf['vf_num'], vf['mac'])
            p_cmd_set_mac_per_vf =  subprocess.Popen(cmd_set_mac_per_vf,shell=True,
                                                     stdout=subprocess.PIPE,
                                                     stderr=subprocess.STDOUT)
            retval = p_cmd_set_mac_per_vf.wait()
            if retval != 0:
                 print 'Failed to set vf mac', cmd_set_mac_per_vf
                 logging.error("Failed to set MAC address to VF {0}".format(vf['vf_num']))
                 sys.exit(1)
    @classmethod
    def bring_vfs_up(cls):
        cmd_bring_vfs_up = "for iface in `ibdev2netdev | awk '{print $5}'`;" + \
                           " do ifconfig $iface up; done"
        p = subprocess.Popen(cmd_bring_vfs_up, shell=True,stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        retval = p.wait()
        if retval != 0:
             logging.error("Failed to bring up all interfaces in ibedev2netdev")

def main():
    logging.basicConfig(format='%(asctime)s %(message)s',
                        level=logging.DEBUG, filename=LOG_FILE)
    try:
        vfs_configurations = MellanoxVfsSettings()
        vfs_configurations.build_vfs_dict()
        vfs_configurations.assign_mac_per_vf()
        vfs_configurations.set_mac_per_vf()
        vfs_configurations.unbind()
        vfs_configurations.bind()
        vfs_configurations.bring_vfs_up()

    except MellanoxVfsSettingsException, exc:
        error_msg = "Failed configuring Mellanox vfs: {0}\n".format(exc)
        sys.stderr.write(error_msg)
        logging.error(exc)
        sys.exit(1)
    success_msg = "Done configuring Mellanox vfs\n"
    sys.stdout.write(success_msg)
    logging.info(success_msg)
    sys.exit(0)


if __name__=="__main__":
    main()
