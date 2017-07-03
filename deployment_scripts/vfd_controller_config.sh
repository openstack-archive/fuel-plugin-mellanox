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

scheduler_default_filters=`grep "scheduler_default_filters=" /etc/nova/nova.conf`
if ! echo $scheduler_default_filters | grep PciPassthroughFilter > /dev/null; then
  scheduler_default_filters="${scheduler_default_filters}, PciPassthroughFilter"
  sed -i "/scheduler_default_filters=.*/ c\\$scheduler_default_filters" /etc/nova/nova.conf
fi
