if [ -d "/var/www/nailgun/bootstrap/" ]; then
  if [ ! -d "/opt/old_bootstrap_image/" ]; then
    mkdir -p /opt/old_bootstrap_image/
  fi
  # If an old bootstrap already exists in the backup dir do not override it with the plugins's new bootstrap
  if [ ! -f /opt/old_bootstrap_image/initramfs.img ]; then
    \cp /var/www/nailgun/bootstrap/initramfs.img /opt/old_bootstrap_image/
    \cp /var/www/nailgun/bootstrap/linux /opt/old_bootstrap_image/
  fi
  if ! [[ `grep release /etc/fuel/version.yaml | grep "7.0"` ]]; then
    \cp $(ls /var/www/nailgun/plugins/mellanox-plugin*/bootstrap/initramfs.img) /var/www/nailgun/bootstrap/
    \cp $(ls /var/www/nailgun/plugins/mellanox-plugin*/bootstrap/linux) /var/www/nailgun/bootstrap/
    command -v dockerctl >/dev/null 2>&1
    if [ $? -eq 0  ];then
      dockerctl copy /var/www/nailgun/bootstrap/initramfs.img cobbler:/var/lib/tftpboot/images/bootstrap/initramfs.img
      dockerctl copy /var/www/nailgun/bootstrap/linux cobbler:/var/lib/tftpboot/images/bootstrap/linux
      \cp $(ls /var/www/nailgun/plugins/mellanox-plugin*/scripts/reboot_bootstrap_nodes) /sbin/
      echo "  `tput bold`Bootstrap discovery image has been replaced for detecting Mellanox Infiniband HW."
      echo "  please reboot your old bootstrap nodes ('reboot_bootstrap_nodes [-e environment_id] [-a] [-h]' can be used).`tput sgr0`"
    fi
  fi
fi
