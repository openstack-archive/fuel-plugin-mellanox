#! /usr/bin/python

import subprocess
import shutil
import os

backuped_bootstrap_id_file = "/opt/orig_bootstrap.txt"
bootstrap_yaml_file = "/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml"
backed_up_bootstrap_yaml_file = "/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml.orig"

if not os.path.isfile(backuped_bootstrap_id_file):
    bootstraps = subprocess.Popen(["fuel-bootstrap", "list"], stdout=subprocess.PIPE).communicate()[0]
    res = [l.split()[1] for l in bootstraps.split('\n') if 'active' in l]
    if res:
        orig_bootstrap_id = res[0]
    else:
        orig_bootstrap_id = "centos"

    with open(backuped_bootstrap_id_file, "w") as f:
        f.write(orig_bootstrap_id)


if not os.path.isfile(backed_up_bootstrap_yaml_file):
    shutil.copyfile(bootstrap_yaml_file, backed_up_bootstrap_yaml_file)
