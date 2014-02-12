#!/bin/bash

set -e

while getopts "p:" opt; do
  case $opt in
    p)
      PLUGIN=$OPTARG
    ;;
    *)
      echo
      echo "Usage: $0 [-p vanilla|spark|hdp]"
      echo "By default the vanilla plugin will be selected"
      exit
    ;;
  esac
done

# Default
if [ -z "$PLUGIN" ]; then
  PLUGIN="vanilla"
fi
# Sanity checks
if [ "$PLUGIN" != "vanilla" -a "$PLUGIN" != "spark" -a "$PLUGIN" != "hdp" ]; then
  echo -e "Unknown plugin selected.\nAborting"
  exit 1
fi
echo "Selected Savanna plugin $PLUGIN"

# Export variables for elements
if [ $PLUGIN = "spark" ]; then
  export DIB_HADOOP_VERSION="2.0.0-mr1-cdh4.5.0"
elif [ $PLUGIN = "vanilla" ]; then
  export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION:-"1.2.1"}
  export fedora_image_name="fedora_savanna_latest"
  export centos_image_name="centos_savanna_latest"
  export OOZIE_DOWNLOAD_URL=${OOZIE_DOWNLOAD_URL:-"http://savanna-files.mirantis.com/oozie-4.0.0.tar.gz"}
  export HIVE_VERSION=${HIVE_VERSION:-"0.11.0"}
elif [ $PLUGIN = "hdp" ]; then
  # Set image names for HDP-based images
  export centos_image_name_hdp_1_3="centos-6_4-64-hdp-1-3"
  export centos_image_name_hdp_2_0="centos-6_4-64-hdp-2-0"
  export centos_image_name_plain="centos-6_4-64-plain"
fi

export JAVA_DOWNLOAD_URL=${JAVA_DOWNLOAD_URL:-"http://download.oracle.com/otn-pub/java/jdk/7u25-b15/jdk-7u25-linux-x64.tar.gz"}
export ubuntu_image_name="ubuntu_savanna_latest"

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

if [ $PLUGIN = "spark" ]; then
  ubuntu_elements_sequence="base vm ubuntu hadoop-cdh spark"
elif [ $PLUGIN = "vanilla" ]; then
  ubuntu_elements_sequence="base vm ubuntu hadoop swift_hadoop oozie mysql hive"
  fedora_elements_sequence="base vm fedora hadoop swift_hadoop oozie mysql hive"
  centos_elements_sequence="vm rhel hadoop swift_hadoop oozie mysql hive redhat-lsb"
elif [ $PLUGIN = "hdp"  ]; then
  # Elements to include in an HDP-based image
  centos_elements_sequence="vm rhel hadoop-hdp redhat-lsb root-passwd savanna-version source-repositories yum"
  # Elements for a plain CentOS image that does not contain HDP or Apache Hadoop
  centos_plain_elements_sequence="vm rhel redhat-lsb root-passwd savanna-version yum"
fi

# Workaround for https://bugs.launchpad.net/diskimage-builder/+bug/1204824
# https://bugs.launchpad.net/savanna/+bug/1252684
if [ $PLUGIN != "spark" -a $PLUGIN != "hdp" -a "$platform" = 'NAME="Ubuntu"' ]; then
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
  if [ $PLUGIN != "spark" ]; then
    mirror_element=" yum-mirror"
    fedora_elements_sequence=$fedora_elements_sequence$mirror_element
  fi
fi

# HDP does not support an Ubuntu image
if [ $PLUGIN != "hdp"  ]; then
  # Creating Ubuntu cloud image
  disk-image-create $ubuntu_elements_sequence -o $ubuntu_image_name
  mv $ubuntu_image_name.qcow2 ../
fi

# Spark uses CDH that is available only for Ubuntu
if [ $PLUGIN != "spark" -a $PLUGIN != "hdp" ]; then
  # Creating Fedora cloud image
  disk-image-create $fedora_elements_sequence -o $fedora_image_name

  # CentOS cloud image:
  # - Disable including 'base' element for CentOS
  # - Export link and filename for CentOS cloud image to download
  # - Patameter 'DIB_IMAGE_SIZE' should be specified for CentOS only
  export DIB_IMAGE_SIZE="10"
  export BASE_IMAGE_FILE="CentOS-6.4-cloud-init.qcow2"
  export DIB_CLOUD_IMAGES="http://savanna-files.mirantis.com"
  # Read Create_CentOS_cloud_image.rst to know how to create CentOS image in qcow2 format
  disk-image-create $centos_elements_sequence -n -o $centos_image_name

  mv $fedora_image_name.qcow2 ../
  mv $centos_image_name.qcow2 ../
fi

if [ $PLUGIN = "hdp"  ]; then
  # Generate HDP images

  # Parameter 'DIB_IMAGE_SIZE' should be specified for Fedora and CentOS
  export DIB_IMAGE_SIZE="10"

  # CentOS cloud image:
  # - Disable including 'base' element for CentOS
  # - Export link and filename for CentOS cloud image to download
  export BASE_IMAGE_FILE="CentOS-6.4-cloud-init.qcow2"
  export DIB_CLOUD_IMAGES="http://savanna-files.mirantis.com"

  # Each image has a root login, password is "hadoop"
  export DIB_PASSWORD="hadoop"

  # generate image with HDP 1.3
  export DIB_HDP_VERSION="1.3"
  disk-image-create $centos_elements_sequence -n -o $centos_image_name_hdp_1_3

  # generate image with HDP 2.0
  export DIB_HDP_VERSION="2.0"
  disk-image-create $centos_elements_sequence -n -o $centos_image_name_hdp_2_0

  # generate plain (no Hadoop components) image for testing
  disk-image-create $centos_plain_elements_sequence -n -o $centos_image_name_plain

  mv $centos_image_name_hdp_1_3.qcow2 ../
  mv $centos_image_name_hdp_2_0.qcow2 ../
  mv $centos_image_name_plain.qcow2 ../
fi


popd # out of $TEMP
rm -rf $TEMP
