
# Verify run is over Fuel Master and we are not During upgrade
if [ -d $FUEL_BOOTSTRAP_DIR ] && [ $1 -eq 0 ]; then

  source /var/www/nailgun/plugins/mellanox-plugin*/scripts/common

  # Return orig active bootstrap
  if [ -f $ORIG_BOOTSTRAP_VERSION_FILE ]; then
    orig_uid=`cat $ORIG_BOOTSTRAP_VERSION_FILE`
    fuel-bootstrap activate $orig_uid
    \rm $ORIG_BOOTSTRAP_VERSION_FILE
  fi

  # Return orig yaml
  if [ -f $ORIG_BOOTSTRAP_CLI_YAML ]; then
    mv $ORIG_BOOTSTRAP_CLI_YAML $BOOTSTRAP_CLI_YAML
  fi

  # Remove extra scripts
  if [ -f "/sbin/reboot_bootstrap_nodes" ]; then
    \rm /sbin/reboot_bootstrap_nodes
  fi

  if [ -f "/sbin/create_mellanox_vpi_bootstrap" ]; then
    \rm /sbin/create_mellanox_vpi_bootstrap
  fi

fi
