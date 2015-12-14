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

# input: list of exclude vf numbers list as string with commas as separaters
# output: string of allowed pci without exclude list with commas between
# 03:00.2,03:00.03,03:00.04,03:00.05,03:00.06,03:00.07,03:01.00, ... etc

import sys
import subprocess

def get_pci_list():
  command_lspci = "lspci -nn | grep Mellanox | grep -i virtual | awk '{print $1}'"
  p_lspci = subprocess.Popen(command_lspci, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  pci_res = list()
  for line in p_lspci.stdout.readlines():
    pci_res.append(line.rstrip())
  retval = p_lspci.wait()
  if retval != 0:
    print 'Failed to execute command lspci.'
    sys.exit()
  else:
    return pci_res

def remove_iser_vfs(exclude_vf_numbers, pci_res):

  # parse the exclude_vf_numbers
  exclude_vf_list = [exclude_vf_list.strip() for exclude_vf_list in exclude_vf_numbers.split(',')]
  for vf_number in exclude_vf_list:
     # remove iSER vf in exclude list
     command_get_iser_vf = "readlink /sys/class/net/eth*/device/virtfn" + vf_number + " | cut -d':' -f2-"
     p = subprocess.Popen(command_get_iser_vf, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
     iser_vf_res = list()
     for iser_vf_res_line in p.stdout.readlines():
       iser_vf_res.append(iser_vf_res_line.rstrip())
     iser_vf_res = list(set(iser_vf_res))
     retval = p.wait()
     if retval != 0:
       print 'Failed to execute command lspci.'
       sys.exit()
     if iser_vf_res[0] in pci_res:
       pci_res.remove(iser_vf_res[0])
  return pci_res

def main(exclude_vf_numbers):

  pci_res = get_pci_list()
  if len( exclude_vf_numbers ) > 0:
    pci_res_without_iser_vf = remove_iser_vfs(exclude_vf_numbers, pci_res)
    pci_res_without_iser_vf_str = ",".join(pci_res_without_iser_vf)
    print pci_res_without_iser_vf_str
    return pci_res_without_iser_vf_str
  else:
    pci_res = ",".join(pci_res)
    print pci_res
    return pci_res
if __name__=="__main__":
  main(sys.argv[1])
