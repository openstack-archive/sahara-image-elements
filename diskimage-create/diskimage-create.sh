#!/bin/bash

set -e

# Export variables for elements

export DIB_HADOOP_VERSION="1.1.2"
export JAVA_DOWNLOAD_URL="http://download.oracle.com/otn-pub/java/jdk/7u25-b15/jdk-7u25-linux-x64.tar.gz"
export ubuntu_image_name="ubuntu_savanna_latest"
export fedora_image_name="fedora_savanna_latest"
export OOZIE_DOWNLOAD_URL="http://a8e0dce84b3f00ed7910-a5806ff0396addabb148d230fde09b7b.r31.cf1.rackcdn.com/oozie-3.3.2.tar.gz"
export HIVE_VERSION="0.11.0"

str=$(head -1 /etc/os-release)
if [ $str = 'NAME="Ubuntu"' ]; then
  apt-get update -y
  apt-get install qemu kpartx git -y
elif [ $str = 'NAME=Fedora' ]; then
  yum update -y
  yum install qemu kpartx git -y
fi

if [ -d /home/$USER/.cache/image-create ]; then
  rm -rf /home/$USER/.cache/image-create/*
fi

cur_dir=$(pwd)
if [ ! -d "DIB_work" ]; then
   mkdir DIB_work
fi
pushd DIB_work

# Cloning repostiroies

rm -rf diskimage-builder
git clone https://github.com/openstack/diskimage-builder
rm -rf savanna-extra
git clone https://github.com/stackforge/savanna-extra

pushd diskimage-builder
export DIB_COMMIT_ID=`git show --format=%H | head -1`
popd

export PATH=$PATH:$cur_dir/DIB_work/diskimage-builder/bin
export ELEMENTS_PATH=$cur_dir/DIB_work/diskimage-builder/elements

pushd savanna-extra
export SAVANNA_ELEMENTS_COMMIT_ID=`git show --format=%H | head -1`
popd

if [ -e $cur_dir/DIB_work/diskimage-builder/sudoers.d/img-build-sudoers ]; then
  cp $cur_dir/DIB_work/diskimage-builder/sudoers.d/img-build-sudoers /etc/sudoers.d/
  chown root:root /etc/sudoers.d/img-build-sudoers
  chmod 0440 /etc/sudoers.d/img-build-sudoers
fi
cp -r $cur_dir/DIB_work/savanna-extra/elements/* $cur_dir/DIB_work/diskimage-builder/elements/

ubuntu_elements_sequence="base vm ubuntu hadoop swift_hadoop oozie mysql hive"
fedora_elements_sequence="base vm fedora hadoop swift_hadoop oozie mysql hive selinux-permissive"

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
popd
rm -rf DIB_work
