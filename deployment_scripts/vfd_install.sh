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

# Set fail on error flag
set -e

function mount_hugepages () {
  mkdir /mnt/huge
  chmod 777 /mnt/huge
  echo "huge /mnt/huge hugetlbfs defaults 0 0" >> /etc/fstab
  mount -a
}

function install_prerequisites () {
  # Compile script prerequisites
  apt-get -y install libnuma-dev git jq

  # VFD prerequisite
  apt-get -y install python-docopt
}

function install_vfd () {
  cd /tmp
  if [ -f mlnx_vfd.tgz ]; then
    rm -f mlnx_vfd.tgz
  fi
  if [ -d mlnx_vfd ]; then
    rm -rf mlnx_vfd
  fi
  wget http://bgate.mellanox.com/openstack/openstack_plugins/mlnx_vfd/beta_0.0.2/mlnx_vfd.tgz
  tar -xzvf mlnx_vfd.tgz
  cd mlnx_vfd/vfd/src/package
  ./export.sh -s /tmp/mlnx_vfd/vfd vfd 1
  ./mk_deb.sh vfd 1
  dpkg -i *.deb
}

function configure_vfd () {
  # Skip if configuration file exists
  if [ -f /etc/vfd/vfd.cfg ]; then
    return
  fi

  # Get the second Mellanox port PCI address
  port_pci=`lspci -D | grep nox | grep ConnectX-[0-9]\]$ | tail -1 | awk '{print $1}'`

  # Copy sample configuration file to main file
  cp /etc/vfd/vfd.cfg.sample /etc/vfd/vfd.cfg.tmp

  # Replace all integer input indication (e.g. <no of vfs to create>)
  # in order to parse the file as json
  sed -i "s/<no of vfs to create>/0/g" /etc/vfd/vfd.cfg.tmp

  # Set the configuration
  jq --arg id $port_pci '.pciids=[{"id":$id, "vfs_count":16,
  "pf_driver": "mlx5_core", "vf_driver": "mlx5_core"}]' /etc/vfd/vfd.cfg.tmp > /etc/vfd/vfd.cfg
  rm /etc/vfd/vfd.cfg.tmp
}

function start_vfd_service () {
  service vfd start
}

function check_vfd_service () {
  iplex ping
  exit $?
}

# mount hugepages if not mounted
if ! mount | grep hugetlbfs > /dev/null ; then
  mount_hugepages
fi

install_prerequisites

install_vfd

configure_vfd

start_vfd_service

check_vfd_service
