#!/bin/bash

sed -i '1a\$(init_mlnx.sh > \/dev\/null 2>\&1) \&\n' /etc/rc.local
exit 0
