#!/usr/bin/env bash -x
# Copyright 2017 Mellanox Technologies, Ltd
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

set -e

function mount_hugepages () {
  mkdir /mnt/huge
  chmod 777 /mnt/huge
  echo "huge /mnt/huge hugetlbfs defaults 0 0" >> /etc/fstab
  mount -a
}

function install_vfd () {
  apt-get -y install python-docopt
  apt-get -y install attlrvfd
}

function configure_vfd () {
  port_pci=`lspci -D | grep nox | grep ConnectX-[0-9]\]$ | tail -1 | awk '{print $1}'`
  cat /etc/vfd/vfd.cfg |  jq --arg id $port_pci '.pciids=[{"id":$id, "vfs_count":16,
  "pf_driver": "mlx5_core", "vf_driver": "mlx5_core"}]' > /etc/vfd/vfd.cfg
}

# mount hugepages if not mounted
if ! mount | grep hugetlbfs > /dev/null ; then
  mount_hugepages
fi

install_vfd

configure_vfd

service vfd start

iplex ping

exit $?
