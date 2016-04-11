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

OFED_DEBS_DIR=/opt/ofed/MLNX_OFED/DEBS

# Set mlnx scripts to run on boot
sed -i '1a\$(init_mlnx.sh > \/dev\/null 2>\&1) \&\n' /etc/rc.local

# Install required packages
dpkg -i ${OFED_DEBS_DIR}/mlnx-ofed-kernel-utils*.deb
dpkg -i ${OFED_DEBS_DIR}/mlnx-ofed-kernel-dkms*.deb

exit 0
