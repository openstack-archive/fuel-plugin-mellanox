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

readonly SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/common

readonly KERNEL_VERSION="$(uname -r)"
readonly OFED_PACKAGE_NAME="mlnx-ofed-fuel"
readonly OFED_BASE_DIR="/opt/ofed"
readonly OFED_SRC_DIR="${OFED_BASE_DIR}/MLNX_OFED"
readonly OFED_SUCCESS_FILE="${OFED_BASE_DIR}/.success"
readonly OFED_INFO="/usr/bin/ofed_info"
OFED_DIR=$OFED_SRC_DIR
OFED_INSTALL_SCRIPT_CMD="${OFED_DIR}/mlnxofedinstall"

function is_ofed_installed () {
  if [ -f ${OFED_SUCCESS_FILE} ] && [ -f ${OFED_INFO} ] && ( ${OFED_INFO} 2>&1 >/dev/null ); then
    installed_ofed_version=`${OFED_INFO} -s`
    logger_print info "OFED is already installed: ${installed_ofed_version}"
    return 0
  else
    return 1
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
    exit 1
  fi
}

function add_kernel_support () {
  # ubuntu doesn't require recompilation in case of kernel change, it supports dkms
  if [ "$DISTRO" == "ubuntu" ]; then
    return
  fi
  OFED_ADD_KERNEL_SUPPORT_SCRIPT="${OFED_DIR}/mlnx_add_kernel_support.sh"
  if [ ! -x $OFED_ADD_KERNEL_SUPPORT_SCRIPT ] ; then
    logger_print error "Failed to find $OFED_ADD_KERNEL_SUPPORT_SCRIPT"
    exit 1
  fi
  OFED_VERSION=$(cat ${OFED_DIR}/.mlnx)
  OFED_ARCH=$(cat ${OFED_DIR}/.arch)
  OFED_DISTRO=$(cat ${OFED_DIR}/distro)
  RECOMPILED_OFED_NAME="MLNX_OFED_LINUX-${OFED_VERSION}-${OFED_DISTRO}-${OFED_ARCH}-ext"
  RECOMPILED_OFED_DIR="${OFED_BASE_DIR}/${RECOMPILED_OFED_NAME}"

  # Recompile OFED in case original OFED at $OFED_DIR doesn't support the existing kernel
  if ( ! grep -Fxq ${KERNEL_VERSION}  ${OFED_DIR}/.supported_kernels ); then
    if [ ! -d ${RECOMPILED_OFED_DIR} ] || ( ! grep -Fxq ${KERNEL_VERSION} ${RECOMPILED_OFED_DIR}/.supported_kernels); then
      logger_print info "Recompiling OFED for kernel ${KERNEL_VERSION}"
      ${OFED_DIR}/mlnx_add_kernel_support.sh --force --yes --make-tgz --mlnx_ofed ${OFED_DIR}
      recompiled_ofed_archive=/tmp/${RECOMPILED_OFED_NAME}.tgz
      tar zxf $recompiled_ofed_archive -C ${OFED_BASE_DIR}
      rm -f $recompiled_ofed_archive
    fi
    OFED_DIR=$RECOMPILED_OFED_DIR
  fi
}

function install_ofed_without_fw_update () {
  OFED_INSTALL_SCRIPT="${OFED_DIR}/mlnxofedinstall"
  if [ ! -x $OFED_INSTALL_SCRIPT ] ; then
    logger_print error "Failed to find $OFED_INSTALL_SCRIPT"
    exit 1
  fi

  logger_print info "Installing OFED drivers"
  OFED_INSTALL_SCRIPT_CMD="/usr/bin/perl ${OFED_INSTALL_SCRIPT}"
  ${OFED_INSTALL_SCRIPT_CMD} --force --enable-sriov --without-fw-update
  rc=$?
  if [ $rc -ne 0 ] ;then
    logger_print error "Failed execute ${OFED_INSTALL_SCRIPT_CMD} error code ${rc}"
    exit 1
  else
    touch ${OFED_SUCCESS_FILE}
  fi
}

function update_fw_if_not_oem () {
  BUS_ID=`lspci | grep -m 1 Mellanox | cut -d' ' -f1`
  if [ -z $BUS_ID ]; then
    logger_print info "Didn't find bus, skipping firmware upgrade"
    exit 0
  fi

  mstflint -d ${BUS_ID} q | grep -i PSID | grep MT_
  if [ $? -ne 0 ] ;then
    logger_print info "Not Mellanox Card, skipping firmware upgrade"
    exit 0
  fi

  logger_print info "Updating FW on Mellanox HCA with BUS ID = ${BUS_ID}"
  ${OFED_INSTALL_SCRIPT_CMD} --fw-update-only
  if [ $? -ne 0 ] ;then
    logger_print error "Failed execute ${OFED_INSTALL_SCRIPT_CMD} error code $?"
    exit 1
  fi
}

function enable_eipoib (){
  if [ $DRIVER == 'eth_ipoib' ]; then
    sed -i s/^E_IPOIB_LOAD.*$/E_IPOIB_LOAD=yes/g /etc/infiniband/openib.conf
    \cp -f ./ipoibd /sbin/ipoibd
  fi
}

if ! is_ofed_installed; then
  # Install mlnx-ofed-fuel rpm/deb package which extracts OFED installation dir
  install_mlnx_ofed_src

  # Add support for the current kernel in case the OFED included in Fuel
  # wasn't compiled for the current kernel
  add_kernel_support

  # First install OFED without SR-IOV and FW upgrade
  install_ofed_without_fw_update

  # Enable Ethernet IP Over Infiniband in case of eth_ipoib driver
  enable_eipoib
fi

# OEM cards require a different dedicated OFED build, this build doesn't
# support them.
update_fw_if_not_oem
