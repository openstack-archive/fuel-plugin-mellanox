
%%post

if [ -d "/var/www/nailgun/bootstrap/" ]; then
  if [ ! -d "/opt/old_bootstrap_image/" ]; then
    mkdir -p /opt/old_bootstrap_image/
  fi
  # If an old bootstrap already exists in the backup dir do not override it with the plugins's new bootstrap
  if [ ! -f /opt/old_bootstrap_image/initramfs.img ]; then
    \cp /var/www/nailgun/bootstrap/initramfs.img /opt/old_bootstrap_image/
    \cp /var/www/nailgun/bootstrap/linux /opt/old_bootstrap_image/
  fi
  \cp $(ls /var/www/nailgun/plugins/mellanox-plugin*/bootstrap/initrd_mlnx*) /var/www/nailgun/bootstrap/
  command -v dockerctl >/dev/null 2>&1
  if [ $? -eq 0  ];then
    dockerctl copy $(ls /var/www/nailgun/bootstrap/initrd_mlnx*) cobbler:/var/lib/tftpboot/
    \cp $(ls /var/www/nailgun/plugins/mellanox-plugin*/scripts/reboot_bootstrap_nodes) /sbin/
    cobbler_profile_vars=$(dockerctl shell cobbler cobbler profile dumpvars --name=bootstrap | grep "kernel_options :" | cut -d':' -f2-)
    initrd_update_image=$(ls /var/www/nailgun/plugins/mellanox-plugin*/bootstrap/ | grep initrd_mlnx* )
    prefix=`echo "initrd=$initrd_update_image"`
    if [[ ! $cobbler_profile_vars == *$prefix* ]]
    then
      # Add the initrd update if not in cobbler vars 
      echo $cobbler_profile_vars > /tmp/pref.txt
      echo -e "$prefix $(cat /tmp/pref.txt | sed s/initrd=.*img//)" > /tmp/pref.txt
      new_cobbler_profile_vars=$(echo "'$(cat /tmp/pref.txt)'")
      dockerctl shell cobbler cobbler profile edit --name bootstrap --kopts=$(echo -e "$new_cobbler_profile_vars")
    fi
    dockerctl shell cobbler cobbler sync
    echo "  `tput bold`Bootstrap discovery image has been replaced for detecting Mellanox Infiniband HW."
    echo "  please reboot your old bootstrap nodes ('reboot_bootstrap_nodes [-e environment_id] [-a] [-h]' can be used).`tput sgr0`"
  fi
fi
