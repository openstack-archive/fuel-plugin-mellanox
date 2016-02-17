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
import subprocess

def get_pci_list():
  command_lspci = "lspci -nn | grep Mellanox | grep -i virtual | awk '{print $1}'"
  p_lspci = subprocess.Popen(command_lspci, shell=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
  pci_res = list()
  for line in p_lspci.stdout.readlines():
    pci_res.append(line.rstrip())
  retval = p_lspci.wait()
  if retval != 0:
    print 'Failed to execute command lspci.'
    sys.exit()
  else:
    return pci_res

def exclude_vfs(exclude_vf_numbers, pci_res, physifc):
  if len( exclude_vf_numbers ) > 0:

    # parse the exclude_vf_numbers
    exclude_vf_list = [exclude_vf_list.strip() for exclude_vf_list in \
                      exclude_vf_numbers.split(',')]
    for vf_number in exclude_vf_list:

       # remove iSER vf in exclude list
       vf_file = "/sys/class/net/{0}/device/virtfn{1}".format(physifc, vf_number)
       if not os.path.exists(vf_file):
         print "VF {1} does not exists for {0}".format(physifc, vf_number)
         exit(1)
       command_get_iser_vf = "readlink {0} | cut -d':' -f2-".format(vf_file)

       p = subprocess.Popen(command_get_iser_vf, shell=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT)

       # to avoid bus IDs duplication when using more than a single port nic
       bus = list(set(p.stdout.readlines())).pop().strip()
       retval = p.wait()
       if retval != 0:
         print 'Failed to execute command lspci.'
         sys.exit()
       if bus in pci_res:
         pci_res.remove(bus)
  return pci_res

def main(exclude_vf_numbers, physnet, physifc):
  pci_res = get_pci_list()
  pci_res = exclude_vfs(exclude_vf_numbers, pci_res, physifc)
  pci_res_str = ",".join('{\"address\":\"' + item + '\", \"physical_network\":\"{0}\"}}'.format(physnet) for item in pci_res)
  pci_res_str2 = "{0}{1}{2}".format('[',pci_res_str,']')
  sys.stdout.write(pci_res_str2)
  return pci_res_str2

def usage():
  print "Wrong number of arguments."
  print 'Usage: '+sys.argv[0]+' [exclude_vf1[,exclude_vf2,..]] <physnet> <physifc>'

if __name__=="__main__":
  if len(sys.argv ) == 3:
      main([], sys.argv[1], sys.argv[2])
  elif len(sys.argv ) == 4:
      main(sys.argv[1], sys.argv[2], sys.argv[3])
  else:
      usage()
