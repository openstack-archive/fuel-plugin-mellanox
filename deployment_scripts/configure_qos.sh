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
  if [[ ! $MLX4_CORE_STR == *enable_vfs_qos* ]];then
    MLX4_CORE_STR="${MLX4_CORE_STR} enable_qos=1 enable_vfs_qos=1"
    echo $MLX4_CORE_STR > $MLX4_CORE_FILE
  else
    logger_print info "QoS already configured in Mellanox driver."
    exit 0
  fi
}

function configure_qos () {
  if is_qos_required; then
    logger_print info "Configuring QoS in Mellanox driver."
    add_to_modprobe_file

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
    return $?
  else
    logger_print info "Skipping QoS configuration in Mellanox driver."
    return 0
  fi
}

#################

case $SCRIPT_MODE in
  'configure')
    if [ "$CX" == "ConnectX-3" ]; then
      configure_qos
    fi
    if [ "$CX" == "ConnectX-4" ]; then
      logger_print info "QoS is not implemented for ConnectX-4." 
    ;;
  *)
    logger_print error "Unsupported execution mode ${SCRIPT_MODE}."
    exit 1
  ;;
esac

exit $?

