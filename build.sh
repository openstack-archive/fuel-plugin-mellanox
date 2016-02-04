#!/bin/bash
# Copyright 2015 Mellanox Technologies, Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function fail_on_error() {
  MSG=$1
  echo $MSG >&2
  exit 1
}

# Verify distrobution
( [ -f /etc/redhat-release ] ) ||
fail_on_error "Mellanox plugin build script supports only Redhat/CentOS"

readonly TOP_DIR=`dirname $0`
readonly TMP_DIR='/tmp'
readonly PLUGIN_BUILDER_DIR="$TMP_DIR/fuel-plugins/"
readonly FUEL_PLUGIN_VERSION=`cat metadata.yaml | grep package_version | awk '{print $2}' | head -c 2 | tail -c 1`
readonly PLUGIN_BUILDER_PACKAGE_DIR="$PLUGIN_BUILDER_DIR/dist"

pushd $TOP_DIR > /dev/null

# Clean if needed
if [ -d "$TMP_DIR/fuel-plugins" ]; then
  rm -rf $TMP_DIR/fuel-plugins
fi
if [ -d ".build" ]; then
  rm -rf .build
fi

# Check FPB version
yum install -y python-pip
pip freeze | grep -q fuel-plugin-builder &&
( pip uninstall fuel-plugin-builder -y || fail_on_error "Failed uninstalling fuel-plugin-builder" )
rm -rf *.rpm

# Install prerequisites
yum install rpm rpm-build dpkg-devel dpkg-dev createrepo tar git python-pip -y ||
fail_on_error "Failed installing some required packages"

# Download Fuel plugin builder
git clone https://github.com/stackforge/fuel-plugins.git $TMP_DIR/fuel-plugins ||
fail_on_error "Failed cloning fuel-plugin-builder git repository"

# Append bootstrap post install to the spec
plugin_template=$PLUGIN_BUILDER_DIR/fuel_plugin_builder/templates/v$FUEL_PLUGIN_VERSION
sed -i '/%post/r specs/post.spec' $plugin_template/build/plugin_rpm.spec.mako

# Install plugin builder
pushd $PLUGIN_BUILDER_DIR > /dev/null
rm -f $PLUGIN_BUILDER_PACKAGE_DIR/*
python setup.py sdist || fail_on_error "Failed building fuel-plugin-builder from source"
pip install $(ls -d $PLUGIN_BUILDER_PACKAGE_DIR/*) || fail_on_error "Failed installing fuel-plugin-builder"
popd > /dev/null

# Create Mellanox Plugin
fuel-plugin-builder --debug --build . || fail_on_error "Building mellanox plugin failed"

# Change permissions of the plugin
sudo chmod 755 mellanox-plugin*

popd > /dev/null
