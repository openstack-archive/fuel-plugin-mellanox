#!/usr/bin/env python

import yaml
import os
import time

plugin = "mellanox-plugin-2.0"
plugin_uri = "http://127.0.0.1:8080/plugins/%s/repositories/ubuntu/" % plugin
current_time = time.strftime("%d_%m_%y_%H_%M")

with open("/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml", 'r') as stream:
    fuel_bootstrap_config = yaml.load(stream)
    repos_names = [repo['name'] for repo in fuel_bootstrap_config['repos']]
    if 'mlnx' not in repos_names:
        fuel_bootstrap_config['repos'].append({'priority': 1100,
                                             'name': 'mlnx',
                                             'suite': '/',
                                             'section': None,
                                             'type': 'deb',
                                             'uri': plugin_uri})
        with open("/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml", "w") as f:
            yaml.dump(fuel_bootstrap_config, f)

    extra_packages = "\'lsof python-libxml2 mlnx-ofed-kernel-dkms mlnx-ofed-kernel-utils\'"
    extra_dir = "/var/www/nailgun/plugins/%s/bootstrap/sync" % plugin
    cmd = "fuel-bootstrap build --debug --package {0} --extra-dir {1} --label 'bootstrap_with_ofed_{2}' --output-dir /tmp/ --script ./bootstrap/sync/opt/mellanox_init.sh --activate".format(extra_packages, extra_dir, current_time)
    os.system(cmd)
