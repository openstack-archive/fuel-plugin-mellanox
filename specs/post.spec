
FUEL_BOOTSTRAP_DIR="/var/www/nailgun/bootstrap/"
PLUGINS_DIR="/var/www/nailgun/plugins/"
BOOTSTRAP_BACKUP_DIR="/opt/old_bootstrap_initrd/"

if [ -d $FUEL_BOOTSTRAP_DIR ]; then
  if [ ! -d $BOOTSTRAP_BACKUP_DIR ]; then
    mkdir -p $BOOTSTRAP_BACKUP_DIR
  fi

  # Backup all available initrd_mlnx* in Fuel bootstrap dir
  for i in `ls $FUEL_BOOTSTRAP_DIR | grep initrd_mlnx`
  do
    if [ ! -f $BOOTSTRAP_BACKUP_DIR/$i ]; then
      \mv $FUEL_BOOTSTRAP_DIR/$i $BOOTSTRAP_BACKUP_DIR
    fi
  done

  \cp $(ls $PLUGINS_DIR/mellanox-plugin*/bootstrap/initrd_mlnx*) $FUEL_BOOTSTRAP_DIR
  command -v dockerctl >/dev/null 2>&1
  if [ $? -eq 0  ];then
    dockerctl copy $(ls $FUEL_BOOTSTRAP_DIR/initrd_mlnx*) cobbler:/var/lib/tftpboot/
    \cp $(ls $PLUGINS_DIR/mellanox-plugin*/scripts/reboot_bootstrap_nodes) /sbin/
    cobbler_profile_vars=$(dockerctl shell cobbler cobbler profile dumpvars --name=bootstrap | grep "kernel_options :" | cut -d':' -f2-)
    initrd_update_image=$(ls $PLUGINS_DIR/mellanox-plugin*/bootstrap/ | grep initrd_mlnx* )
    prefix=`echo "initrd=$initrd_update_image"`
    if [[ ! $cobbler_profile_vars == *$initrd_update_image* ]]
    then
      # Add the initrd update if not in cobbler vars
      new_cobbler_profile_vars=$(echo " $prefix $(echo $cobbler_profile_vars | sed s/initrd=.*img//)")
      dockerctl shell cobbler cobbler profile edit --name bootstrap --kopts="${new_cobbler_profile_vars}"
    fi
    dockerctl shell cobbler cobbler sync
    echo "  `tput bold`Bootstrap discovery image has been replaced for detecting Mellanox Infiniband HW."
    echo "  please reboot your old bootstrap nodes ('reboot_bootstrap_nodes [-e environment_id] [-a] [-h]' can be used).`tput sgr0`"
  fi
fi
