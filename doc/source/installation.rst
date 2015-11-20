.. _installation:

Installation Guide
==================

Mellanox plugin installation
----------------------------

To install Mellanox plugin, follow these steps:

#. Download the plugin from `Fuel Plugins Catalog <https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/>`_.

#. Copy the plugin on already installed Fuel Master node.
   If you do not have the Fuel Master node yet, see `Quick Start Guide <https://software.mirantis.com/quick-start/>`_ ::

   # scp mellanox-plugin-2.0-2.0.0-1.noarch.rpm root@<Fuel_Master_ip>:/tmp

#. Install the plugin::

        # cd /tmp
        # fuel plugins --install mellanox-plugin-2.0-2.0.0-1.noarch.rpm




   .. note:: Mellanox plugin installation replaces your bootstrap image only in Fuel 6.1 at this stage.
              The original image is backed up in `/opt/old_bootstrap_image/`.

#. Verify the plugin was installed successfully by having it listed using ``fuel plugins`` command::


        # fuel plugins
        id | name              | version | package_version
        ---|-------------------|---------|----------------
        1  | mellanox-plugin   | 2.0.0   | 2.0.0

#. You must boot your target nodes with the new bootstrap image (installed by the plugin) **after** the plugin is installed. (In Fuel 7.0, the plugin doesn’t replace bootstrap images and uses Mirantis bootstrap images)
   Check your Fuel’s node status by running ``fuel node`` command.

   a. If you already have nodes in “discover” status (with the original bootstrap image)
   .. image:: _static/list_fuel_nodes.png
      :alt: A screenshot of the nodes list
      :scale: 90%
    
   Use the ``reboot_bootstrap_nodes`` script to reboot your nodes with the new image. For more info about using the script ``run reboot_bootstrap_nodes --help``.

    b. If ``fuel node`` command doesn’t show any nodes then you can boot your nodes only once after the plugin is installed.
