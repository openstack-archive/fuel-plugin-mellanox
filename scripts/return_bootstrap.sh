#!/bin/bash

# Return orig active bootstrap
bootstrap_file="/opt/orig_bootstrap.txt"
orig_uid=`cat $bootstrap_file`
fuel-bootstrap activate $orig_uid
\rm $bootstrap_file

# Return orig yaml
mv /etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml.orig /etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml
