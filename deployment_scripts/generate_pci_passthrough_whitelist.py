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

# the physical_network must be passed to it as a parameter

# we need to add the VF pci addresses to the white list but not to add 
# the first VF as it's reserved for iSER

# input: list of addresses as 03:00.0 that is got from this command:
# lspci -nn | grep Mella | grep -i Virtual | awk '{print $1}'

# get the available busses

# for some bus, check available functions and then slots

# as for the physnet, get it as a passed parameter

# example: 
# pci_passthrough_whitelist= {"address":{"domain": ".*", "bus": "02", "slot": "01", "function": "[2-7]"}, "physical_network":"net1"}

# will take a list of exclude list, the list will have numbers as input with spaces between
# the numbers reflects the number of iSER VF
# the output is a string with domains to pass for nova pci white list
# 03:00.2 03:00.03 03:00.04 03:00.04 03:00.05 03:00.06 03:00.07 03:01.00 03:01.01
import sys
import subprocess
def merge(pci_passthrough_whitelist_d, iser_vf):
  # assume we always have 1 bus
  bus = pci_passthrough_whitelist_d['address'][0]['bus']
  # create a regex with all above this vf and what is less than it
  pci_regex = 'pci_passthrough_whitelist= {"address":{"domain": ".*",
                "bus": "', bus
  print pci_regex
  


def main(physnet):

  command = "lspci -nn | grep Mellanox | grep -i virtual | awk '{print $1}'"
  p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  pci_res = list()
  i = 0
  for line in p.stdout.readlines():
    pci_res.append(line.rstrip())
  retval = p.wait()


  # remove iSER vf if iSER was required
  #if [ $ISER == true ]:
  command = "readlink /sys/class/net/eth*/device/virtfn0 | cut -d':' -f2-"
  p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  iser_vf_res = list()
  for iser_vf_res_line in p.stdout.readlines():
    iser_vf_res.append(iser_vf_res_line.rstrip())
  retval = p.wait()
  
  if iser_vf_res[0] == pci_res[0]:
    pci_res.remove(iser_vf_res[0])

  pci_passthrough_whitelist_d = dict().fromkeys(['address', 'physical_network'])
  # physical_network gpt as a parameter from puppet class
  pci_passthrough_whitelist_d['physical_network'] = physnet
  pci_passthrough_whitelist_d['address'] = list()

  for pci in pci_res:
    address_d = dict().fromkeys(['domain', 'bus', 'slot', 'function'])
    address_d['bus'] = pci.split(':')[0]
    address_d['slot'] = pci.split(':')[1].split('.')[0]
    address_d['function'] = pci.split(':')[1].split('.')[1]
    address_d['domain'] = '.*'
    pci_passthrough_whitelist_d['address'].append(address_d, iser_vf_res[0])

if __name__=="__main__":
  main(sys.argv[1])
