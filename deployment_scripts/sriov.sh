#!/bin/bash -x

readonly SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/common

function get_port_type() {
  if [ $DRIVER == 'mlx4_en' ]; then
    port_type=2
  elif [ $DRIVER == 'eth_ipoib' ]; then
    port_type=1
  fi
  echo $port_type
}
function get_num_probe_vfs () {
  ([ $ISER == true ] && echo 1 ) || echo 0
}

function calculate_total_vfs () {
  if [ "${USER_NUM_OF_VFS}" -ne "${USER_NUM_OF_VFS}" ] 2>/dev/null ||
      [ "${USER_NUM_OF_VFS}" -gt ${MAX_VFS} ] ||
      [ "${USER_NUM_OF_VFS}" -lt ${MIN_VFS} ]; then
    logger_print err "Illegal number of VFs ${USER_NUM_OF_VFS}, value
                      should be an integer between ${MIN_VFS},${MAX_VFS}"
    exit 1
  fi
  num_of_vfs=${USER_NUM_OF_VFS}
  if [ $((${USER_NUM_OF_VFS} % 2)) -eq 1 ]; then
    let num_of_vfs="${USER_NUM_OF_VFS} + 1" # number of vfs is odd and <= 64, then +1 is legal
    logger_print info "Configuring ${num_of_vfs} VFs (only even number is currently supported)"
  fi
  echo ${num_of_vfs}
}

function set_modprobe_file () {
  readonly PROBE_VFS=`get_num_probe_vfs`
  readonly MLX4_CORE_FILE="/etc/modprobe.d/mlx4_core.conf"
  readonly TOTAL_VFS=`calculate_total_vfs`
  readonly PORT_TYPE=`get_port_type`
  MLX4_CORE_STR="options mlx4_core
                 enable_64b_cqe_eqe=0
                 log_num_mgm_entry_size=-1
                 port_type_array=${PORT_TYPE},${PORT_TYPE}"
  [ -z ${TOTAL_VFS} ] && exit 1
  if [[ $TOTAL_VFS -gt 0 ]]; then
    MLX4_CORE_STR="${MLX4_CORE_STR} num_vfs=${TOTAL_VFS}"
    if [[ $PROBE_VFS -gt 0 ]]; then
      MLX4_CORE_STR="${MLX4_CORE_STR} probe_vf=${PROBE_VFS}"
    fi
  fi
  echo ${MLX4_CORE_STR} > ${MLX4_CORE_FILE}
}

function set_kernel_params () {
  NEW_KERNEL_PARAMS="intel_iommu=on"
  if [ "$DISTRO" == "redhat" ]; then
    grub_file='/boot/grub/grub.conf'
    kernel_line=`egrep 'kernel\s+/vmlinuz' ${grub_file} | grep -v '#'`
  elif [ "$DISTRO" == "ubuntu" ]; then
    grub_file='/boot/grub/grub.cfg'
    kernel_line=$(echo "$(egrep 'linux\s+/vmlinuz' ${grub_file} | grep -v '#')" | head -1)
  fi

  if [[ $? -ne 0 ]]; then
    echo "Couldn't find kernel line in grub file" >&2 && exit 1
  fi
  if ! grep -q 'intel_iommu' ${grub_file} ; then
    line_num=$(echo "$(grep -n "${kernel_line}" ${grub_file} |cut -f1 -d: )" | head -1)
    new_kernel_line="${kernel_line} ${NEW_KERNEL_PARAMS}"
    # delete original line
    sed -i "${line_num}d" ${grub_file}
    # insert the corrected line on the same line number
    sed -i "${line_num}i\ ${new_kernel_line}" ${grub_file}
  fi
}

function burn_vfs_in_fw () {
  total_vfs=$1
  # required for mlxconfig to discover mlnx devices
  service openibd start 2>&1 >/dev/null
  service mst start 2>&1 >/dev/null
  devices=$(mst status | grep pciconf | awk '{print $1}')
  failed=false
  for dev in $devices; do
    logger_print debug "device=$dev"
    query_str=$(mlxconfig -d $dev q)
    sriov_enabled=$(echo "$query_str" | grep SRIOV_EN | awk '{print $2}')
    current_num_of_vfs=$(echo "$query_str" | grep NUM_OF_VFS | awk '{print $2}')
    if [ $sriov_enabled -eq 1 ] 2>/dev/null; then
      logger_print debug "Detected SR-IOV is already enabled"
    else
      logger_print debug "Detected SR-IOV is disabled"
    fi
    if [ "$total_vfs" -le "$current_num_of_vfs" ] 2>/dev/null; then
      logger_print debug "Current num of VFs is ${current_num_of_vfs}, required number is ${total_vfs}"
    fi
    mlxconfig -y -d $dev s SRIOV_EN=1 NUM_OF_VFS=$total_vfs 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
      failed=true
      logger_print err "Failed changing number of VFs in HCA ${dev}"
    fi
  done
  service mst stop 2>&1 >/dev/null
  if [ "$failed" == true ]; then
    exit 1
  fi
}

#################

if [ $SRIOV == true ]; then
  set_modprobe_file `get_num_probe_vfs`
  set_kernel_params
  total_vfs=`calculate_total_vfs`
  [ -z ${total_vfs} ] && exit 1
  burn_vfs_in_fw ${total_vfs}
else
  logger_print info "SR-IOV feature was not chosen by user, skipping VFs configuration"
fi
