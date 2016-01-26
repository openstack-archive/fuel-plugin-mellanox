source /var/www/nailgun/plugins/mellanox-plugin*/scripts/common

if [ -d $FUEL_BOOTSTRAP_DIR ]; then

  # Return orig active bootstrap
  orig_uid=`cat $ORIG_BOOTSTRAP_VERSION_FILE`
  fuel-bootstrap activate $orig_uid
  \rm $ORIG_BOOTSTRAP_VERSION_FILE

  # Return orig yaml
  mv /etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml.orig \
     /etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml

  # Remove extra scripts
  \rm /sbin/reboot_bootstrap_nodes \
      /sbin/create_mellanox_vpi_bootstrap
fi
