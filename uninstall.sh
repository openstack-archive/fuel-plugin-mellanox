PLUGIN_SCRIPTS_DIR="/var/www/nailgun/plugins/$MELLANOX_PLUGIN_NAME/scripts/"

if [ -d $FUEL_BOOTSTRAP_DIR ]; then

  # Load original Fuel Master's bootstrap and yaml file
  $PLUGIN_SCRIPTS_DIR/return_bootstrap.sh

  # Remove extra scripts
  \rm /sbin/reboot_bootstrap_nodes \
      /sbin/create_mellanox_vpi_bootstrap
fi
