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
ROLES="primary-controller controller compute cinder"
ASTUTE_FILE=/etc/astute.yaml

function check_symlink () {
  symlink_source=$(readlink ${ASTUTE_FILE})
}

# Check if a symlink already exists
check_symlink
if [ $? -eq 0 ]; then
  logger_print info "Symbolic link already exists: ${ASTUTE_FILE} --> ${symlink_source}"
  exit 0
fi

# Create astute.yaml symlink to any of the <role>.yaml files
for role in $ROLES; do
  role_file=/etc/"$role".yaml
  if [ -f $role_file ]; then
    ln -s -f $role_file ${ASTUTE_FILE}
    break
  fi
done

check_symlink
if [ $? -ne 0 ]; then
  logger_print error "Failed creating a symbolic link for ${ASTUTE_FILE}"
  exit 1
else
  logger_print info "Symbolic link ${ASTUTE_FILE} --> ${symlink_source} was created"
  exit 0
fi
