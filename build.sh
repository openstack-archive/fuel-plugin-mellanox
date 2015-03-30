#!/bin/bash -ex

function fail_on_error() {
  RC=$1
  MSG=$2
  if [ $RC -ne 0 ]; then
    echo $MSG >&2
    exit 1
  fi
}

# Verify distrobution
[ -f /etc/redhat-release ] || [ -f /etc/centos-release ] ||
fail_on_error $? "Mellanox plugin build script supports only Redhat / CentOS distro."

readonly TOP_DIR=`dirname $0`
readonly TMP_DIR='/tmp'
readonly PLUGIN_BUILDER_DIR="$TMP_DIR/fuel-plugins/fuel_plugin_builder"
readonly PLUGIN_BUILDER_PACKAGE_DIR="$PLUGIN_BUILDER_DIR/dist"
pushd $TOP_DIR > /dev/null

# Clean if needed
if [ -d "$TMP_DIR/fuel-plugins" ]; then
  rm -rf $TMP_DIR/fuel-plugins
fi
if [ -d ".build" ]; then
  rm -rf .build
fi

pip freeze | grep -q fuel-plugin-builder &&
( pip uninstall fuel-plugin-builder -y || fail_on_error $? "Failed uninstalling fuel-plugin-builder" )
rm -rf *.rpm

# Install prerequisites
yum install rpm rpm-build dpkg-devel createrepo tar git python-pip -y ||
fail_on_error $? "Failed installing some required packages"

# Download Fuel plugin builder
git clone https://github.com/stackforge/fuel-plugins.git $TMP_DIR/fuel-plugins ||
fail_on_error $? "Failed cloning fuel-plugin-builder git repository"

# Append bootstrap post install to the spec
cat specs/post.spec >> $PLUGIN_BUILDER_DIR/fuel_plugin_builder/templates/build/plugin_rpm.spec.mako

# Install plugin builder
pushd $PLUGIN_BUILDER_DIR > /dev/null
rm -f $PLUGIN_BUILDER_PACKAGE_DIR/*
python setup.py sdist || fail_on_error $? "Failed building fuel-plugin-builder from source"
pip install $(ls -d $PLUGIN_BUILDER_PACKAGE_DIR/*) || fail_on_error $? "Failed installing fuel-plugin-builder"
popd > /dev/null

# Create Mellanox Plugin
fuel-plugin-builder --build . || fail_on_error $? "Building mellanox plugin failed"

popd > /dev/null
