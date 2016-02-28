#!/bin/bash -x

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

readonly SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/common
readonly SCRIPT_MODE=$1

function is_qos_required () {
  [ $QOS == true ] && [ $DRIVER == 'mlx4_en' ]
  return $?
}

function add_to_modprobe_file() {
  MLX4_CORE_FILE="/etc/modprobe.d/mlx4_core.conf"
  MLX4_CORE_STR=`cat $MLX4_CORE_FILE`
  MLX4_CORE_STR="${MLX4_CORE_STR} enable_vfs_qos=1"
  echo $MLX4_CORE_STR > $MLX4_CORE_FILE
}

function configure_qos () {
  if is_qos_required; then
    logger_print info "Configuring QoS in Mellanox driver."
    add_to_modprobe_file
    service openibd restart
    return $?
  else
    logger_print info "Skipping QoS configuration in Mellanox driver."
    return 0
  fi
}

#################

case $SCRIPT_MODE in
  'configure')
    configure_qos
    ;;
  *)
    logger_print error "Unsupported execution mode ${SCRIPT_MODE}."
    exit 1
  ;;
esac

exit $?

