#!/bin/bash -ex

# Verify distrobution
if [ ! -f /etc/redhat-release ] && [ ! -f /etc/centos-release ];then
  echo "Mellanox plugin build script supports only Redhat / CentOS distro."
  exit 1
fi

readonly TOP_DIR=`dirname $0`
readonly TMP_DIR='/tmp'
readonly PLUGIN_BUILDER_DIR="$TMP_DIR/fuel-plugins/fuel_plugin_builder"

pushd $TOP_DIR > /dev/null

# Clean if needed
if [ -d "$TMP_DIR/fuel-plugins" ]; then
  rm -rf $TMP_DIR/fuel-plugins
fi
if [ -d ".build" ]; then
  rm -rf .build
fi
pip freeze | grep -q fuel-plugin-builder && pip uninstall fuel-plugin-builder -y
rm -rf *.rpm

# Install prerequisites
yum install rpm rpm-build dpkg-devel createrepo tar git python-pip -y

# Download Fuel plugin builder
git clone https://github.com/stackforge/fuel-plugins.git $TMP_DIR/fuel-plugins

# Append bootstrap post install to the spec
cat specs/post.spec >> $PLUGIN_BUILDER_DIR/fuel_plugin_builder/templates/build/plugin_rpm.spec.mako

# Install plugin builder
pushd $PLUGIN_BUILDER_DIR > /dev/null
python setup.py sdist
pip install dist/fuel-plugin-builder-2.0.0.dev.tar.gz
popd > /dev/null

# Create Mellanox Plugin
fuel-plugin-builder --build .

popd > /dev/null
