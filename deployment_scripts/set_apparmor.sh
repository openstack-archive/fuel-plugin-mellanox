#!/bin/bash -x
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

readonly SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/common

if [ $SRIOV == true ]; then
  SRIOV_EXTRA_LINES='  # Those rules are required for SR-IOV to function properly'\
'\n  \/sys\/devices\/system\/** r,\n  \/sys\/bus\/pci\/devices\/ r,'\
'\n  \/sys\/bus\/pci\/devices\/** r,\n  \/sys\/devices\/pci*\/** rw,'\
'\n  \/{,var\/}run\/openvswitch\/vhu* rw,'
  APPARMOR_D_LIBVIRT=/etc/apparmor.d/abstractions/libvirt-qemu

  if ! grep -q '# Those rules are required for SR-IOV' $APPARMOR_D_LIBVIRT; then
    sed -i "s/^.*signal.*receive.*peer.*libvirtd.*$/$SRIOV_EXTRA_LINES\n\n&/" \
      /etc/apparmor.d/abstractions/libvirt-qemu
    sudo service apparmor reload
    sudo service libvirtd restart
    sudo service nova-compute restart
  fi
fi

exit $?
