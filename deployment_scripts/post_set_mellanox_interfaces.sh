#!/bin/bash
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

source ./common

# Set correct VF number in multi role computes
# (e.g. cinder & compute)
if ([[ $ROLES == *compute* ]] && [[ ! $ROLES == "compute" ]]) \
    && [ $SRIOV == true ] ; then

  if [ $CX == 'ConnectX-3' ]; then

    # Update VFs
    ./sriov.sh configure

    # Kill tgt daemons if exists
    tgt_locks=`find /var/run/ -name tgtd* | wc -l`
    if [ $tgt_locks -ne 0 ];then
      \rm -f /var/run/tgtd* && killall -9 tgtd
      service tgt stop
    fi

    service openibd restart && service openvswitch-switch restart

    if [ $tgt_locks -ne 0 ];then
      service tgt start
    fi
  fi
  if [ $CX == 'ConnectX-4' ]; then
    service openibd restart && service openvswitch-switch restart
  fi
  # Verify VFs
  ./sriov.sh validate

fi
