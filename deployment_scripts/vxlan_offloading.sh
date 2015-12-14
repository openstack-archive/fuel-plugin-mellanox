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
readonly SCRIPT_MODE=$1

function is_vxlan_offloading_required () {
  [ $VXLAN_OFFLOADING == true ] && [ $DRIVER == 'mlx4_en' ]
  return $?
}

function configure_vxlan_offloading() {
 if is_vxlan_offloading_required; then
   logger_print info "Configuring VXLAN OFFLOADING."
   ./set_modprobe_file
   return $?
 else
  # not required, no need to configure it
  logger_print info "Skipping VXLAN OFFLOADING configuration."
  return 0
 fi
}
function validate_vxlan_offloading() {
 # to be filled later
}

#################

configure_vxlan_offloading
case $SCRIPT_MODE in
  'configure')
    configure_vxlan_offloading
    ;;
  'validate')
    # to be added later.
    validate_vxlan_offloading
    ;;
  *)
    logger_print error "Unsupported execution mode ${SCRIPT_MODE}"
    exit 1
  ;;
esac

exit $?
