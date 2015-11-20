.. _installation:

Installation Guide
==================

Mellanox plugin installation
----------------------------

To install Mellanox plugin, follow these steps:

#. Download the plugin from `Fuel Plugins Catalog <https://software.mirantis.com/fuel-plugins>`_.

#. Copy the plugin on already installed Fuel Master node.
   If you do not have the Fuel Master node yet, see `Quick Start Guide <https://software.mirantis.com/quick-start/>`_ ::

   # scp mellanox-plugin-2.0-2.0.0-1.noarch.rpm root@<Fuel_Master_ip>:/tmp

#. Install the plugin::

        # cd /tmp
        # fuel plugins --install mellanox-plugin-2.0-2.0.0-1.noarch.rpm




   .. note:: Mellanox plugin installation replaces your bootstrap image only in Fuel 6.1 at this stage.
              The original image is backed up in `/opt/old_bootstrap_image/`.

#. Check if the plugin was installed successfully::


        # fuel plugins
        id | name              | version | package_version
        ---|-------------------|---------|----------------
        1  | mellanox-plugin   | 2.0.0   | 2.0.0
