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

readonly SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/common

if [ "$DISTRO" == 'redhat' ]; then
  sed -i /etc/sysconfig/system-config-firewall -e s/enabled/disabled/g
  if (iptables -S | grep -q "FORWARD -j REJECT --reject-with icmp-host-prohibited"); then
    iptables -D  FORWARD -j REJECT --reject-with icmp-host-prohibited
    sed -i '/FORWARD -j REJECT --reject-with icmp-host-prohibited/d' /etc/sysconfig/iptables
    sed -i '/FORWARD -j REJECT --reject-with icmp-host-prohibited/d' /etc/sysconfig/iptables.save
  fi
fi
