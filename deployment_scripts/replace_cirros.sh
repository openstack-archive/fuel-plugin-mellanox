#!/bin/bash
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

source ./common

function install_cirros() {
  if [ $DISTRO == 'redhat' ]; then
    yum install -y $1
  elif [ $DISTRO == 'ubuntu' ]; then
    apt-get install -y $1
  fi
}

if [ $SRIOV == false ]; then
  logger_print info "Skipping cirros image replacement, Mellanox-Cirros is required
                     only for SR-IOV deployments"
  exit 0
fi

if [ $DRIVER == 'eth_ipoib' ]; then
  CIRROS_PACKAGE_NAME='cirros-testvm-mellanox-ib'
else
  CIRROS_PACKAGE_NAME='cirros-testvm-mellanox'
fi

ruby ./delete_images.rb 2>/dev/null &&
puppet apply -e 'package { "cirros-testvm": ensure => absent }' &&
puppet apply -e 'package { "cirros-testvm-mellanox": ensure => absent }' &&
puppet apply -e 'package { "cirros-testvm-mellanox-ib": ensure => absent }' &&
install_cirros $CIRROS_PACKAGE_NAME &&
ruby /etc/puppet/modules/osnailyfacter/modular/astute/upload_cirros.rb 2>/dev/null
if [ $? -ne 0 ]; then
  logger_print error "Replacing Cirros image with Mellanox-Cirros image failed"
  exit 1
else
  logger_print info "Cirros image was successfully replaced with Mellanox-Cirros image"
  exit 0
fi
