#!/bin/bash

set -e

# Export variables for elements

export DIB_HADOOP_VERSION="1.2.1"
export JAVA_DOWNLOAD_URL="http://download.oracle.com/otn-pub/java/jdk/7u25-b15/jdk-7u25-linux-x64.tar.gz"
export ubuntu_image_name="ubuntu_savanna_latest"
export fedora_image_name="fedora_savanna_latest"
export OOZIE_DOWNLOAD_URL="http://savanna-files.mirantis.com/oozie-4.0.0.tar.gz"
export HIVE_VERSION="0.11.0"

platform=$(head -1 /etc/os-release)
if [ $platform = 'NAME="Ubuntu"' ]; then
  apt-get update -y
  apt-get install qemu kpartx git -y
elif [ $platform = 'NAME=Fedora' ]; then
  yum update -y
  yum install qemu kpartx git -y
fi

TEMP=$(mktemp -d diskimage-create.XXXXXX)
pushd $TEMP

export DIB_IMAGE_CACHE=$TEMP/.cache-image-create

# Cloning repostiroies

git clone https://git.openstack.org/openstack/diskimage-builder
git clone https://git.openstack.org/openstack/savanna-image-elements

pushd diskimage-builder
export DIB_COMMIT_ID=`git rev-parse HEAD`
popd

export PATH=$PATH:$PWD/diskimage-builder/bin
export ELEMENTS_PATH=$PWD/diskimage-builder/elements:$PWD/savanna-image-elements/elements

pushd savanna-image-elements
export SAVANNA_ELEMENTS_COMMIT_ID=`git rev-parse HEAD`
popd

ubuntu_elements_sequence="base vm ubuntu hadoop swift_hadoop oozie mysql hive"
fedora_elements_sequence="base vm fedora hadoop swift_hadoop oozie mysql hive"

# Workaround for https://bugs.launchpad.net/diskimage-builder/+bug/1204824
if [ $platform = 'NAME="Ubuntu"' ]; then
  echo "**************************************************************"
  echo "WARNING: As a workaround for DIB bug 1204824, you are about to"
  echo "         create a Fedora image that has SELinux disabled. Do  "
  echo "         not use this image in production.                    "
  echo "**************************************************************"
  fedora_elements_sequence="$fedora_elements_sequence selinux-permissive"
  fedora_image_name="$fedora_image_name.selinux-permissive"
fi

if [ -n "$USE_MIRRORS" ]; then
  mirror_element=" apt-mirror"
  ubuntu_elements_sequence=$ubuntu_elements_sequence$mirror_element
  mirror_element=" yum-mirror"
  fedora_elements_sequence=$fedora_elements_sequence$mirror_element
fi

# Creating Ubuntu cloud image
disk-image-create $ubuntu_elements_sequence -o $ubuntu_image_name

# Creating Fedora cloud image
# Patameter 'DIB_IMAGE_SIZE' should be specified for Fedora only
export DIB_IMAGE_SIZE="10"
disk-image-create $fedora_elements_sequence -o $fedora_image_name

mv $fedora_image_name.qcow2 ../
mv $ubuntu_image_name.qcow2 ../

popd # out of $TEMP
rm -rf $TEMP
