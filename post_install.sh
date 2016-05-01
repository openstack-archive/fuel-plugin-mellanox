source /var/www/nailgun/plugins/mellanox-plugin*/scripts/common

if [ -d $FUEL_BOOTSTRAP_DIR ]; then

  # Backup original bootstrap yaml and UID
  $PLUGIN_SCRIPTS_DIR/backup_orig_bootstrap.py

  # Add bootstrap scripts to Fuel Master
  \cp $PLUGIN_SCRIPTS_DIR/reboot_bootstrap_nodes \
      $PLUGIN_SCRIPTS_DIR/create_mellanox_bootstrap \
      /sbin/

  # Print post install message
  echo "  `tput bold`In order to create Bootstrap discovery image for detecting Mellanox Infiniband HW:"
  echo "    1. Please build a new bootstrap ('create_mellanox_bootstrap [--link_type] [-h, --help] can be used')."
  echo "    2. Please reboot your old bootstrap nodes"
  echo "       ('reboot_bootstrap_nodes [-e environment_id] [-a] [-h]' can be used).`tput sgr0`"

fi
