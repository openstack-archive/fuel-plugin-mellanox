#!/bin/bash
# Copyright (c) 2014 Mellanox Technologies. All rights reserved.
#
# This Software is licensed under one of the following licenses:
#
# 1) under the terms of the "Common Public License 1.0" a copy of which is
#    available from the Open Source Initiative, see
#    http://www.opensource.org/licenses/cpl.php.
#
# 2) under the terms of the "The BSD License" a copy of which is
#    available from the Open Source Initiative, see
#    http://www.opensource.org/licenses/bsd-license.php.
#
# 3) under the terms of the "GNU General Public License (GPL) Version 2" a
#    copy of which is available from the Open Source Initiative, see
#    http://www.opensource.org/licenses/gpl-license.php.
#
# Licensee has the right to choose one of the above licenses.
#
# Redistributions of source code must retain the above copyright
# notice and one of the license notices.
#
# Redistributions in binary form must reproduce both the above copyright
# notice, one of the license notices in the documentation
# and/or other materials provided with the distribution.
set -x

readonly SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/common

readonly SUCCESS=0
readonly FAILURE=1
readonly KERNEL_VERSION="$(uname -r)"
readonly OFED_PACKAGE_NAME="mlnx-ofed-fuel"
readonly OFED_BASE_DIR="/opt/ofed"
readonly OFED_SRC_DIR="${OFED_BASE_DIR}/MLNX_OFED"
readonly OFED_SUCCESS_FILE="${OFED_BASE_DIR}/.success"
readonly OFED_INFO="/usr/bin/ofed_info"
OFED_DIR=$OFED_SRC_DIR

function check_if_ofed_installed () {
  if [ -f ${OFED_SUCCESS_FILE} ] && [ -f ${OFED_INFO} ] && ( ${OFED_INFO} 2>&1 >/dev/null ); then
    installed_ofed_version=`${OFED_INFO} -s`
    logger_print info "OFED is already installed: ${installed_ofed_version}"
    exit 0
  fi
}

function install_mlnx_ofed_src () {
  logger_print info "Installing ${OFED_PACKAGE_NAME} source code"
  if [ "$DISTRO" == "redhat" ]; then
    yum install ${OFED_PACKAGE_NAME} -y
  elif [ "$DISTRO" == "ubuntu" ]; then
    apt-get install ${OFED_PACKAGE_NAME} -y
  fi
  if [ $? -ne 0 ]; then
    logger_print error "Failed installing ${OFED_PACKAGE_NAME} package"
    exit ${FAILURE}
  fi
}

function add_kernel_support () {
  if [ "$DISTRO" == "ubuntu" ]; then
    return
  fi
  OFED_ADD_KERNEL_SUPPORT_SCRIPT="${OFED_DIR}/mlnx_add_kernel_support.sh"
  OFED_VERSION=$(cat ${OFED_DIR}/.mlnx)
  OFED_ARCH=$(cat ${OFED_DIR}/.arch)
  OFED_DISTRO=$(cat ${OFED_DIR}/distro)
  RECOMPILED_OFED_NAME="MLNX_OFED_LINUX-${OFED_VERSION}-${OFED_DISTRO}-${OFED_ARCH}-ext"
  RECOMPILED_OFED_DIR="${OFED_BASE_DIR}/${RECOMPILED_OFED_NAME}"

  if [ ! -x $OFED_ADD_KERNEL_SUPPORT_SCRIPT ] ; then
    logger_print error "Failed to find $OFED_ADD_KERNEL_SUPPORT_SCRIPT"
    exit ${FAILURE}
  fi

  # Recompile OFED in case original OFED at $OFED_DIR doesn't support the existing kernel
  if ( ! grep -Fxq ${KERNEL_VERSION}  ${OFED_DIR}/.supported_kernels ); then
    if [ ! -d ${RECOMPILED_OFED_DIR} ] || ( ! grep -Fxq ${KERNEL_VERSION} ${RECOMPILED_OFED_DIR}/.supported_kernels); then
      logger_print info "Recompiling OFED for kernel ${KERNEL_VERSION}"
      ${OFED_DIR}/mlnx_add_kernel_support.sh --force --yes --make-tgz --mlnx_ofed ${OFED_DIR}
      tar zxf /tmp/${RECOMPILED_OFED_NAME}.tgz -C ${OFED_BASE_DIR}
    fi
    OFED_DIR=$RECOMPILED_OFED_DIR
  fi
}

function install_ofed_without_fw_update () {
  OFED_INSTALL_SCRIPT="${OFED_DIR}/mlnxofedinstall"
  if [ ! -x $OFED_INSTALL_SCRIPT ] ; then
    logger_print error "Failed to find $OFED_INSTALL_SCRIPT"
    exit ${FAILURE}
  fi

  logger_print info "Installing OFED drivers"
  OFED_INSTALL_SCRIPT_CMD="/usr/bin/perl ${OFED_INSTALL_SCRIPT}"
  ${OFED_INSTALL_SCRIPT_CMD} --force --without-fw-update
  if [ $? -ne ${SUCCESS} ] ;then
    logger_print error "Failed execute ${OFED_INSTALL_SCRIPT_CMD} error code $?"
    exit ${FAILURE}
  fi
}

function update_fw_if_not_oem () {
  BUS_ID=`lspci | grep -m 1 Mellanox | cut -d' ' -f1`
  if [ -z $BUS_ID ]; then
    logger_print info "Not found Bus, skipping firmware upgrade"
    exit ${SUCCESS}
  fi

  logger_print info "BUS ID = ${BUS_ID}"
  mstflint -d ${BUS_ID} q | grep -i PSID | grep MT_
  if [ $? -ne ${SUCCESS} ] ;then
    logger_print info "Not Mellanox Card, skipping firmware upgrade"
    exit ${SUCCESS}
  fi

  logger_print info "Enabling SR-IOV in OFED & FW"
  ${OFED_INSTALL_SCRIPT_CMD} --force --enable-sriov
  if [ $? -eq ${SUCCESS} ] ;then
    touch ${OFED_SUCCESS_FILE}
  else
    logger_print error "Failed enable sriov ${OFED_INSTALL_SCRIPT_CMD} error code $?"
    exit ${FAILURE}
  fi
}

check_if_ofed_installed
install_mlnx_ofed_src
add_kernel_support
install_ofed_without_fw_update
update_fw_if_not_oem

