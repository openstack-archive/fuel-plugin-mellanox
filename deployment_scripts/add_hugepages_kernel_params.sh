#!/usr/bin/env bash
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

cmd_line=`cat /etc/default/grub | grep GRUB_CMDLINE_LINUX=`
if ! echo $cmd_line | grep hugepages > /dev/null ; then
  eval `cat /etc/default/grub | grep GRUB_CMDLINE_LINUX=`
  GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX default_hugepagesz=2M hugepagesz=2M hugepages=4096"
  sed -i "/GRUB_CMDLINE_LINUX=.*/ c\\GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_LINUX}\"" /etc/default/grub
  update-grub
fi
