#!/bin/bash

source ./common
ROLES="primary-controller controller compute cinder"
ASTUTE_FILE=/etc/astute.yaml

function check_symlink () {
  symlink_source=$(readlink ${ASTUTE_FILE})
}

# Check if a symlink already exists
check_symlink &&
logger_print info "Symbolic link already exists: ${ASTUTE_FILE} --> ${symlink_source}" &&
exit 0

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
  logger_print error "Failed creating a symbolic link for ${ASTUTE_FILE}" && exit 1
else
  logger_print info "Symbolic link ${ASTUTE_FILE} --> ${symlink_source} was created"
fi
