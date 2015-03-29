
%%post
if [ -d "/var/www/nailgun/bootstrap/" ]; then
  mkdir -p /opt/old_bootstrap_image/
  mv /var/www/nailgun/bootstrap/* /opt/old_bootstrap_image/
  \cp $(ls /var/www/nailgun/plugins/mellanox_plugin*/bootstrap/initramfs.img) /var/www/nailgun/bootstrap/
  \cp $(ls /var/www/nailgun/plugins/mellanox_plugin*/bootstrap/linux) /var/www/nailgun/bootstrap/
  command -v dockerctl >/dev/null 2>&1
  if [ $? -eq 0  ];then
    dockerctl copy /var/www/nailgun/bootstrap/initramfs.img cobbler:/var/lib/tftpboot/images/bootstrap/initramfs.img
    dockerctl copy /var/www/nailgun/bootstrap/linux cobbler:/var/lib/tftpboot/images/bootstrap/linux
    \cp $(ls /var/www/nailgun/plugins/mellanox_plugin*/scripts/reboot_bootstrap_nodes) /sbin/
    echo "  `tput bold`Bootstrap discovery image has been replaced for detecting Mellanox Infiniband HW."
    echo "  please reboot your old bootstrap nodes ('reboot_bootstrap_nodes [environment_id|--help]' can be used).`tput sgr0`"
  fi
fi
