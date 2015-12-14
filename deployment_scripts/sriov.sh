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
readonly FALLBACK_NUM_VFS=8
readonly SRIOV_ENABLED_FLAG=1
readonly VF_MAC_CACHING_TIMEOUT=1
readonly VF_MAC_CACHING_TIMEOUT_DEF=300
readonly NEW_KERNEL_PARAM="intel_iommu=on"
readonly GRUB_FILE_CENTOS="/boot/grub/grub.conf"
readonly GRUB_FILE_UBUNTU="/boot/grub/grub.cfg"

function get_port_type() {
  if [ $DRIVER == 'mlx4_en' ]; then
    port_type=2
  elif [ $DRIVER == 'eth_ipoib' ]; then
    port_type=1
  fi
  echo $port_type
}

function get_num_probe_vfs () {
  if [ $SRIOV == true ] && [ $DRIVER == 'mlx4_en' ]; then
    probe_vfs=`calculate_total_vfs`
  elif [ $ISER == true ] && [ $DRIVER == 'mlx4_en' ]; then
    probe_vfs=1
  else
    probe_vfs=0
  fi
  echo $probe_vfs
}

function calculate_total_vfs () {
  # validate num of vfs is an integer, 0 <= num <= 64
  if [ "${USER_NUM_OF_VFS}" -ne "${USER_NUM_OF_VFS}" ] 2>/dev/null ||
      [ "${USER_NUM_OF_VFS}" -gt ${MAX_VFS} ] ||
      [ "${USER_NUM_OF_VFS}" -lt ${MIN_VFS} ]; then
    logger_print error "Illegal number of VFs ${USER_NUM_OF_VFS}, value
                        should be an integer between ${MIN_VFS},${MAX_VFS}"
    return 1
  fi
  num_of_vfs=0
  # SR-IOV is enabled, the given number of VFs is used
  # iSER is also enabled, the iSER VF is among the given SR-IOV VFs
  if [ $SRIOV == true ]; then
    num_of_vfs=${USER_NUM_OF_VFS}
  # SR-IOV is disabled with iSER enabled, then use only the storage VF
  elif [ $ISER == true ]; then
    num_of_vfs=`get_num_probe_vfs`
  fi
  # Enforce even num of vfs
  if [ $((${num_of_vfs} % 2)) -eq 1 ]; then
    let num_of_vfs="${num_of_vfs} + 1" # number of vfs is odd and <= 64, then +1 is legal
  fi
  echo ${num_of_vfs}
}

# Reduce mac caching time since VF is used for iSER with non permanent MAC
function reduce_mac_caching_timeout () {
  probes=`get_num_probe_vfs`
  if [ "$probes" == "1" ]; then
    timeout=$VF_MAC_CACHING_TIMEOUT
  else
    timeout=$VF_MAC_CACHING_TIMEOUT_DEF
  fi
  sysctl_conf set 'net.ipv4.route.gc_timeout' "$timeout"
}

function is_vxlan_offloading_required () {
  [ $VXLAN_OFFLOADING == true ]
  return $?
}

function set_modprobe_file () {
  PROBE_VFS=`get_num_probe_vfs`
  MLX4_CORE_FILE="/etc/modprobe.d/mlx4_core.conf"
  PORT_TYPE=`get_port_type`
  MLX4_CORE_STR="options mlx4_core
                 enable_64b_cqe_eqe=0
                 debug_level=1"

  TOTAL_VFS=$1
  if is_vxlan_offloading_required; then
    MLX4_CORE_STR="${MLX4_CORE_STR} log_num_mgm_entry_size=-1"
  fi
  MLX4_CORE_STR="${MLX4_CORE_STR} port_type_array=${PORT_TYPE},${PORT_TYPE}"
  if [[ $TOTAL_VFS -gt 0 ]]; then
    MLX4_CORE_STR="${MLX4_CORE_STR} num_vfs=${TOTAL_VFS}"
    if [[ $PROBE_VFS -gt 0 ]]; then
      MLX4_CORE_STR="${MLX4_CORE_STR} probe_vf=${TOTAL_VFS}"
    fi
  fi
  echo ${MLX4_CORE_STR} > ${MLX4_CORE_FILE}

}

function set_kernel_params () {
  if [ "$DISTRO" == "redhat" ]; then
    grub_file=${GRUB_FILE_CENTOS}
    kernel_line=`egrep 'kernel\s+/vmlinuz' ${grub_file} | grep -v '#'`
  elif [ "$DISTRO" == "ubuntu" ]; then
    grub_file=${GRUB_FILE_UBUNTU}
    kernel_line=$(echo "$(egrep 'linux\s+/vmlinuz' ${grub_file} | grep -v '#')" | head -1)
  fi

  if [[ $? -ne 0 ]]; then
    echo "Couldn't find kernel line in grub file" >&2 && return 1
  fi
  if ! grep -q ${NEW_KERNEL_PARAM} ${grub_file} ; then
    line_num=$(echo "$(grep -n "${kernel_line}" ${grub_file} |cut -f1 -d: )" | head -1)
    new_kernel_line="${kernel_line} ${NEW_KERNEL_PARAM}"
    # delete original line
    sed -i "${line_num}d" ${grub_file}
    # insert the corrected line on the same line number
    sed -i "${line_num}i\ ${new_kernel_line}" ${grub_file}
  fi
  reduce_mac_caching_timeout
}

function burn_vfs_in_fw () {
  total_vfs=$1
  # required for mlxconfig to discover mlnx devices
  service openibd start &>/dev/null
  service mst start &>/dev/null
  devices=$(mst status | grep pciconf | awk '{print $1}')
  for dev in $devices; do
    logger_print debug "device=$dev"
    mlxconfig -d $dev q | grep SRIOV | awk '{print $2}' | grep $SRIOV_ENABLED_FLAG  &>/dev/null
    sriov_enabled=$?
    current_num_of_vfs=`mlxconfig -d $dev q | grep NUM_OF_VFS | awk '{print $2}'`
    if [ $sriov_enabled -eq 0 ] 2>/dev/null; then
      logger_print debug "Detected SR-IOV is already enabled"
    else
      logger_print debug "Detected SR-IOV is disabled"
    fi
    if [[ ! "$total_vfs" == "$current_num_of_vfs" ]] 2>/dev/null; then
      logger_print debug "Current allowed number of VFs is ${current_num_of_vfs}, required number is ${total_vfs}"
      mlxconfig -y -d $dev s SRIOV_EN=1 NUM_OF_VFS=$total_vfs 2>&1 >/dev/null
      if [ $? -ne 0 ]; then
        logger_print error "Failed changing number of VFs in FW for HCA ${dev}"
      fi
    else
      logger_print debug "Current number of VFs is correctly set to ${current_num_of_vfs} in FW."
    fi
  done
  service mst stop &>/dev/null
}

function is_sriov_required () {
  [ $SRIOV == true ] ||
  ( [ $ISER == true ] && [ $DRIVER == 'mlx4_en' ] )
  return $?
}

function configure_sriov () {
  if is_sriov_required; then
    # Calculate the total amount of virtual functions, based on user seclection
    total_vfs=`calculate_total_vfs`
    if [ -z ${total_vfs} ]; then
      exit 1
    fi
    logger_print info "Configuring ${total_vfs} virtual functions
                       (only even number is currently supported)"

    probe_vfs=`get_num_probe_vfs`
    port_type=`get_port_type`
    set_modprobe_file $total_vfs &&
    set_kernel_params &&
    burn_vfs_in_fw $total_vfs
    return $?
  else
    logger_print info "Skipping SR-IOV configuration"
    return 0
  fi
}

function validate_sriov () {
  if ! is_sriov_required; then
    logger_print info "Skipping SR-IOV validation, no virtual functions required"
    return 0
  fi
  logger_print info "Validating SR-IOV is enabled, and the required
                     amount of virtual functions exist"
  # get number of VFs
  current_num_vfs=`lspci | grep -i mellanox | grep -i virtual | wc -l`
  total_vfs=`calculate_total_vfs`
  if [ -z ${total_vfs} ]; then
    exit 1
  fi
  # check if kernel was loaded with the new parameter
  grep ${NEW_KERNEL_PARAM} /proc/cmdline
  has_kernel_param_status=$?
  if [ $has_kernel_param_status -eq 0 ]; then
    if [ $current_num_vfs -eq $total_vfs ]; then
      logger_print info "Successfully verified SR-IOV is enabled with ${current_num_vfs} VFs"
      return 0
    fi
  else
    logger_print error "Kernel did not come up with the kernel parameter: ${NEW_KERNEL_PARAM},
                        SR-IOV configuration failed"
    return 1
  fi

  # fallback only if kernel param exists and amount of vfs is not as expcted
  logger_print error "Failed , trying to fallback to ${FALLBACK_NUM_VFS}"
  probe_vfs=`get_num_probe_vfs`
  port_type=`get_port_type`
  set_modprobe_file $FALLBACK_NUM_VFS
  service openibd restart &> /dev/null
  current_num_vfs=`lspci | grep -i mellanox | grep -i virtual | wc -l`
  if [ $current_num_vfs -eq $FALLBACK_NUM_VFS ]; then
    logger_print info "Fallback to ${FALLBACK_NUM_VFS} succeeded"
    return 0
  else
    logger_print error "Failed to configure SR-IOV"
    return 1
  fi
}

#################

case $SCRIPT_MODE in
  'configure')
    configure_sriov
    ;;
  'validate')
    validate_sriov
    ;;
  *)
    logger_print error "Unsupported execution mode ${SCRIPT_MODE}"
    exit 1
  ;;
esac

exit $?
