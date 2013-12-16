#!/bin/bash

set -e

# Export variables for elements

export DIB_HADOOP_VERSION="1.2.1"
export JAVA_DOWNLOAD_URL="http://download.oracle.com/otn-pub/java/jdk/7u25-b15/jdk-7u25-linux-x64.tar.gz"
export ubuntu_image_name="ubuntu_savanna_latest"
export fedora_image_name="fedora_savanna_latest"
export centos_image_name="centos_savanna_latest"
export OOZIE_DOWNLOAD_URL="http://savanna-files.mirantis.com/oozie-4.0.0.tar.gz"
export HIVE_VERSION="0.11.0"

if [ -e /etc/os-release ]; then
  platform=$(head -1 /etc/os-release)
  if [ $platform = 'NAME="Ubuntu"' ]; then
    apt-get update -y
    apt-get install qemu kpartx git -y
  elif [ $platform = 'NAME=Fedora' ]; then
    yum update -y
    yum install qemu kpartx git -y
  fi
else
  platform=$(head -1 /etc/system-release | grep CentOS)
  if [ -z $platform ]; then
    yum update -y
    yum install qemu-kvm kpartx git -y
  else
    echo -e "Unknown Host OS. Impossible to build images.\nAborting"
  fi
fi

base_dir="$(dirname $(readlink -e $0))"

TEMP=$(mktemp -d diskimage-create.XXXXXX)
pushd $TEMP

export DIB_IMAGE_CACHE=$TEMP/.cache-image-create

# Working with repositories
# disk-image-builder repo

if [ -z $DIB_REPO_PATH ]; then
  git clone https://git.openstack.org/openstack/diskimage-builder
  DIB_REPO_PATH="$(pwd)/diskimage-builder"
fi

export PATH=$PATH:$DIB_REPO_PATH/bin

pushd $DIB_REPO_PATH
export DIB_COMMIT_ID=`git rev-parse HEAD`
popd

export ELEMENTS_PATH="$DIB_REPO_PATH/elements"

# savanna-image-elements repo

if [ -z $SIM_REPO_PATH ]; then
  SIM_REPO_PATH="$(dirname $base_dir)"
  if [ $(basename $SIM_REPO_PATH) != "savanna-image-elements" ]; then
    echo "Can't find Savanna-image-elements repository. Cloning it."
    git clone https://git.openstack.org/openstack/savanna-image-elements
    SIM_REPO_PATH="$(pwd)/savanna-image-elements"
  fi
fi

ELEMENTS_PATH=$ELEMENTS_PATH:$SIM_REPO_PATH/elements

pushd $SIM_REPO_PATH
export SAVANNA_ELEMENTS_COMMIT_ID=`git rev-parse HEAD`
popd

ubuntu_elements_sequence="base vm ubuntu hadoop swift_hadoop oozie mysql hive"
fedora_elements_sequence="base vm fedora hadoop swift_hadoop oozie mysql hive"
centos_elements_sequence="vm rhel hadoop swift_hadoop oozie mysql hive redhat-lsb"

# Workaround for https://bugs.launchpad.net/diskimage-builder/+bug/1204824
# https://bugs.launchpad.net/savanna/+bug/1252684
if [ "$platform" = 'NAME="Ubuntu"' ]; then
  echo "**************************************************************"
  echo "WARNING: As a workaround for DIB bug 1204824, you are about to"
  echo "         create a Fedora and CentOS images that has SELinux    "
  echo "         disabled. Do not use these images in production.       "
  echo "**************************************************************"
  fedora_elements_sequence="$fedora_elements_sequence selinux-permissive"
  centos_elements_sequence="$centos_elements_sequence selinux-permissive"
  fedora_image_name="$fedora_image_name.selinux-permissive"
  centos_image_name="$centos_image_name.selinux-permissive"
fi

# CentOS mirror will be added some later
if [ -n "$USE_MIRRORS" ]; then
  mirror_element=" apt-mirror"
  ubuntu_elements_sequence=$ubuntu_elements_sequence$mirror_element
  mirror_element=" yum-mirror"
  fedora_elements_sequence=$fedora_elements_sequence$mirror_element
fi

# Creating Ubuntu cloud image
disk-image-create $ubuntu_elements_sequence -o $ubuntu_image_name

# Creating Fedora cloud image
# Patameter 'DIB_IMAGE_SIZE' should be specified for Fedora and CentOS
export DIB_IMAGE_SIZE="10"
disk-image-create $fedora_elements_sequence -o $fedora_image_name

# CentOS cloud image:
# - Disable including 'base' element for CentOS
# - Export link and filename for CentOS cloud image to download
export BASE_IMAGE_FILE="CentOS-6.4-cloud-init.qcow2"
export DIB_CLOUD_IMAGES="http://savanna-files.mirantis.com"
# Read Create_CentOS_cloud_image.rst to know how to create CentOS image in qcow2 format
disk-image-create $centos_elements_sequence -n -o $centos_image_name

mv $fedora_image_name.qcow2 ../
mv $ubuntu_image_name.qcow2 ../
mv $centos_image_name.qcow2 ../

popd # out of $TEMP
rm -rf $TEMP
