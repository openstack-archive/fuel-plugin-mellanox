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
readonly FALLBACK_NUM_VFS=8
readonly SRIOV_ENABLED_FLAG=1
readonly VF_MAC_CACHING_TIMEOUT=1
readonly VF_MAC_CACHING_TIMEOUT_DEF=300
readonly NEW_KERNEL_PARAM="intel_iommu=on"
readonly GRUB_FILE_CENTOS="/boot/grub/grub.conf"
readonly GRUB_FILE_UBUNTU="/boot/grub/grub.cfg"

function get_port_type() {
  if [ $NETWORK_TYPE == 'ethernet' ]; then
    port_type=2
  else
    port_type=1
  fi
  echo $port_type
}

function get_num_probe_vfs () {
  if [ `get_port_type` -eq "2" ]; then
    probe_vfs=`calculate_total_vfs`
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

  # Set Compute VFs storage network
  if [ $SRIOV == true ]; then

    # If ROLES not set and not controller or compute
    if ([ -z $ROLES ] && [[ ! $ROLE == *controller* ]]) || \
       ([ $ROLE == compute ] || [[ $ROLES == *compute* ]]); then
      num_of_vfs=${USER_NUM_OF_VFS}
    fi
  fi

  # Set Ethernet RDMA storage network
  if [ $ISER == true ] && [ `get_port_type` -eq "2" ] \
     && [ $num_of_vfs -eq 0 ]; then
    num_of_vfs=1
  fi

  # Enforce even num of vfs
  if [ $((${num_of_vfs} % 2)) -eq 1 ]; then
    let num_of_vfs="${num_of_vfs} + 1"
  fi
  echo ${num_of_vfs}
}

# Reduce mac caching time since VF is used for iSER with non permanent MAC
function reduce_mac_caching_timeout () {
  probes=`get_num_probe_vfs`
  if [ $probes -ge 1 ]; then
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
                 enable_64b_cqe_eqe=0"
  if [[ $DEBUG == "true" ]];then
    MLX4_CORE_STR="${MLX4_CORE_STR} debug_level=1"
  fi

  TOTAL_VFS=$1
  MLX4_CORE_STR="${MLX4_CORE_STR} port_type_array=${PORT_TYPE},${PORT_TYPE}"
  if [[ $TOTAL_VFS -gt 0 ]]; then
    if [ $PORT_TYPE -eq 1 ]; then
      num_vfs="${TOTAL_VFS}"
      probe_vf="${TOTAL_VFS}"
    else
      num_vfs="${TOTAL_VFS},0,0"
      probe_vf="${TOTAL_VFS},0,0"
    fi

    MLX4_CORE_STR="${MLX4_CORE_STR} num_vfs=$num_vfs"
    if [[ $PROBE_VFS -gt 0 ]]; then
      MLX4_CORE_STR="${MLX4_CORE_STR} probe_vf=$probe_vf"
    fi
  fi
  MLX4_CORE_STR="${MLX4_CORE_STR} log_num_mgm_entry_size=-1"
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
  if [ $CX == 'ConnectX-3' ]; then
    # required for mlxconfig to discover mlnx devices
    service openibd start &>/dev/null
    service mst start &>/dev/null
    devices=$(mst status -v | grep $(echo $CX | tr -d '-')| grep pciconf | awk '{print $2}')
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
        logger_print debug "Trying mlxconfig -y -d ${dev} s SRIOV_EN=1 NUM_OF_VFS=${total_vfs}"
        mlxconfig -y -d $dev s SRIOV_EN=1 NUM_OF_VFS=$total_vfs 2>&1 >/dev/null
        if [ $? -ne 0 ]; then
          logger_print error "Failed changing number of VFs in FW for HCA ${dev}"
        fi
      else
        logger_print debug "Current number of VFs is correctly set to ${current_num_of_vfs} in FW."
      fi
    done
    service mst stop &>/dev/null
  fi
  if [ $CX == 'ConnectX-4' ]; then
    # required for mlxconfig to discover mlnx devices
    service openibd start &>/dev/null
    service mst start &>/dev/null
    devices=$(mst status -v | grep $(echo $CX | tr -d '-') | grep pciconf | awk '{print $2}')
    for dev in $devices; do
      current_fw_vfs=`mlxconfig -d $dev q | grep NUM_OF_VFS | awk '{print $2}'`
      if [ "$total_vfs" -gt "$current_fw_vfs" ]; then
        logger_print debug "device=$dev"
        logger_print debug "Trying mlxconfig -d ${dev} -y set NUM_OF_VFS=${total_vfs}"
        mlxconfig -d $dev -y set NUM_OF_VFS=$total_vfs
      fi
    done
  fi
}

function is_sriov_required () {
  [ $SRIOV == true ] ||
  ( [ $ISER == true ] && [ `get_port_type` -eq "2" ] )
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
    set_kernel_params &&
    burn_vfs_in_fw $total_vfs
    if [ $CX == 'ConnectX-3' ]; then
      set_modprobe_file $total_vfs &&
      logger_print info "Detected: ConnectX-3 card"
    fi

    if [ $CX == 'ConnectX-4' ]; then
      set_sriov $total_vfs &&
      logger_print info "Detected: ConnectX-4 card"
    fi

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

  if [ $CX == 'ConnectX-3' ]; then
    set_modprobe_file $FALLBACK_NUM_VFS
    service openibd restart &> /dev/null
  fi
  if [ $CX == 'ConnectX-4' ]; then
    set_sriov $FALLBACK_NUM_VFS
  fi
 
  current_num_vfs=`lspci | grep -i mellanox | grep -i virtual | wc -l`
  if [ $current_num_vfs -eq $FALLBACK_NUM_VFS ]; then
    logger_print info "Fallback to ${FALLBACK_NUM_VFS} succeeded"
    return 0
  else
    logger_print error "Failed to configure SR-IOV"
    return 1
  fi
}

function set_sriov () {
  PORT_TYPE=`get_port_type`
  TOTAL_VFS=$1
  device_up=$PHYSICAL_PORT

  if [ ${#device_up} -eq 0 ]; then
    logger_print error "Failed to find mlx5 up ports in ibdev2netdev."
    exit 1
  else
    if [ "$(lspci | grep -i mellanox | grep -i virtual | wc -l)" -ne "$TOTAL_VFS" ]; then

      if [ ! $REBOOT_REQUIRED == true ]; then
        res=`echo 0 > /sys/class/net/${device_up}/device/mlx5_num_vfs`
        res=`echo ${TOTAL_VFS} > /sys/class/net/${device_up}/device/mlx5_num_vfs`
        if [ ! $? -eq 0 ]; then
          logger_print error "Failed to write $TOTAL_VFS > /sys/class/net/${device_up}/device/mlx5_num_vfs"
          exit 1
        fi

        # Give MACs to created VFs
        python ./configure_mellanox_vfs.py ${TOTAL_VFS}
      fi

      # Make number of VFs and their MACs persistent
      persistent_ifup_script=/etc/network/if-up.d/persistent_mlnx_params
      echo "#!/bin/bash" > $persistent_ifup_script
      chmod +x $persistent_ifup_script
      echo "if ! lspci | grep -i mellanox | grep -i virtual; then" >> $persistent_ifup_script
      echo "echo 0 > /sys/class/net/${device_up}/device/mlx5_num_vfs" >> $persistent_ifup_script
      echo "echo ${TOTAL_VFS} > /sys/class/net/${device_up}/device/mlx5_num_vfs" >> $persistent_ifup_script
      echo "python /etc/fuel/plugins/mellanox-plugin-*/configure_mellanox_vfs.py ${TOTAL_VFS}" >> $persistent_ifup_script
      echo "fi" >> $persistent_ifup_script
      echo "if [ -f /etc/init.d/tgt ]; then /etc/init.d/tgt force-reload; else exit 0; fi" >> $persistent_ifup_script

      if [ $REBOOT_REQUIRED == true ]; then
        logger_print debug "Configured total vfs ${TOTAL_VFS} on ${device_up} will apply \
                            on next reboot as reboot is required"
      else
        if [ ! $? -eq 0 ]; then
          logger_print error "Failed to write $TOTAL_VFS > /sys/class/net/${device_up}/device/mlx5_num_vfs"
          exit 1
        else
          logger_print debug "Configured total vfs ${TOTAL_VFS} on ${device_up}"
        fi
      fi
    fi
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
