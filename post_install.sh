
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

source /var/www/nailgun/plugins/mellanox-plugin*/scripts/common

if [ -d $FUEL_BOOTSTRAP_DIR ]; then

  # Backup original bootstrap yaml and UID
  $PLUGIN_SCRIPTS_DIR/backup_orig_bootstrap.py

  # Add bootstrap scripts to Fuel Master
  \cp $PLUGIN_SCRIPTS_DIR/reboot_bootstrap_nodes \
      $PLUGIN_SCRIPTS_DIR/create_mellanox_bootstrap \
      /sbin/

  # Print post install message
  echo "  `tput bold`In order to create Bootstrap discovery image for detecting"\
       "Mellanox Infiniband HW:"
  echo "    1. Please build a new bootstrap ('create_mellanox_bootstrap [-h]"\ 
       "[--link_type {eth,ib,current}] [--max_num_vfs MAX_NUM_VFS]')"
  echo "    2. Please reboot your old bootstrap nodes"
  echo "       ('reboot_bootstrap_nodes [-e environment_id] [-a] [-h]' can be used).`tput sgr0`"

fi
