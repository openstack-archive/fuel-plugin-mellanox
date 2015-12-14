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

function set_modprobe_file () {
  TOTAL_VFS=$1
  PROBE_VFS=$2
  PORT_TYPE=$3

  MLX4_CORE_FILE="/etc/modprobe.d/mlx4_core.conf"
  MLX4_CORE_STR="options mlx4_core
                 enable_64b_cqe_eqe=0
                 log_num_mgm_entry_size=-1"

  if is_vxlan_offloading_required; then
    MLX4_CORE_STR="${MLX4_CORE_STR} debug=1"
  fi
  if is_sriov_required; then  
    MLX4_CORE_STR="${MLX4_CORE_STR} port_type_array=${PORT_TYPE},${PORT_TYPE}"

    if [[ $TOTAL_VFS -gt 0 ]]; then
      MLX4_CORE_STR="${MLX4_CORE_STR} num_vfs=${TOTAL_VFS}"
      if [[ $PROBE_VFS -gt 0 ]]; then
        MLX4_CORE_STR="${MLX4_CORE_STR} probe_vf=${TOTAL_VFS}"
      fi
    fi
  fi

  echo ${MLX4_CORE_STR} > ${MLX4_CORE_FILE}
}

function is_sriov_required () {
  [ $SRIOV == true ] ||
  ( [ $ISER == true ] && [ $DRIVER == 'mlx4_en' ] )
  return $?
}

function is_vxlan_offloading_required () {
  [ $VXLAN_OFFLOADING == true ] 
  return $?
}

#################
set_modprobe_file $1 $2 $3

exit $?
