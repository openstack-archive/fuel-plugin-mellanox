#!/bin/bash -x
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

if [ $SRIOV == true ]; then
  lsmod | grep -q vfio || (modprobe vfio && modprobe vfio_pci)
  grep -q vfio /etc/rc.local || echo "modprobe vfio" >> /etc/rc.local &&
  grep -q vfio_pci /etc/rc.local || echo "modprobe vfio_pci" >> /etc/rc.local
fi

exit $?
