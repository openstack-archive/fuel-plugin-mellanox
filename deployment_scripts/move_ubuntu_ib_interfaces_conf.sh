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

# If IB interface is configured then append IB configurations
# to the standard /etc/network/interfaces file, for MLNX_OFED
# drivers to find it
if [ $DISTRO == 'ubuntu' ] && [ $DRIVER == 'eth_ipoib' ] \
  && [ -f /etc/network/interfaces.d/ifcfg-ib* ]; then
  echo >> /etc/network/interfaces
  cat /etc/network/interfaces.d/ifcfg-ib* >> /etc/network/interfaces
  \rm -f /etc/network/interfaces.d/ifcfg-ib0*
  service openvswitch-switch restart
fi
