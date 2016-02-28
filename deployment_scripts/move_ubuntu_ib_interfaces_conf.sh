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
if [ $DISTRO == 'ubuntu' ] && [ $DRIVER == 'eth_ipoib' ]; then
  ib_files=`find /etc/network/interfaces.d/ -name ifcfg-ib* | wc -l`
  if [ $ib_files != 0 ];then
    echo >> /etc/network/interfaces
    cat /etc/network/interfaces.d/ifcfg-ib* >> /etc/network/interfaces
    \rm -f /etc/network/interfaces.d/ifcfg-ib0*
  fi

  # Kill tgt daemons if exists
  tgt_locks=`find /var/run/ -name tgtd* | wc -l`
  if [ $tgt_locks -ne 0 ];then
    \rm -f /var/run/tgtd* && killall -9 tgtd
    service tgt stop
  fi

  service openibd restart && service openvswitch-switch restart

  if [[ $ROLE == compute ]] && [ -f /etc/init.d/nova-compute ]; then
    service nova-compute restart
  fi

  if [ $tgt_locks -ne 0 ];then
    service tgt start
  fi
fi
