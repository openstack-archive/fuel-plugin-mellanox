EXTRA_SCRIPTS="/sbin/reboot_bootstrap_node
               /sbin/create_mellanox_bootstrap"
source /var/www/nailgun/plugins/mellanox-plugin*/scripts/common

# Verify run is over Fuel Master and we are not During upgrade
if [ -d $FUEL_BOOTSTRAP_DIR ] && [ $1 -eq 0 ]; then

  # Return orig yaml
  if [ -f $ORIG_BOOTSTRAP_CLI_YAML ]; then
    mv $ORIG_BOOTSTRAP_CLI_YAML $BOOTSTRAP_CLI_YAML
  fi

  for script in $EXTRA_SCRIPTS; do
    # Remove extra scripts
    if [ -e $script ]; then
      \rm $script
    fi
  done
fi
