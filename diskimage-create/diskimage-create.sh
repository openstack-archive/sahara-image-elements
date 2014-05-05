#!/bin/bash

set -e

export IMAGE_SIZE=$DIB_IMAGE_SIZE
# This will unset parameter DIB_IMAGE_SIZE for Ubuntu and Fedora vanilla images
unset DIB_IMAGE_SIZE

# DEBUG_MODE is set by the -d flag, debug is enabled if the value is "true"
DEBUG_MODE="false"

while getopts "p:i:v:d" opt; do
  case $opt in
    p)
      PLUGIN=$OPTARG
    ;;
    i)
      IMAGE_TYPE=$OPTARG
     ;;
    v)
      HADOOP_VERSION=$OPTARG
    ;;
    d)
      DEBUG_MODE="true"
    ;;
    *)
      echo
      echo "Usage: $(basename $0)"
      echo "         [-p vanilla|spark|hdp]"
      echo "         [-i ubuntu|fedora|centos]"
      echo "         [-v 1|2|plain]"
      echo "         [-d]"
      echo "   '-p' is plugin version (default: vanilla)"
      echo "   '-i' is image type (default: all supported by plugin)"
      echo "   '-v' is hadoop version (default: all supported by plugin)"
      echo "   '-d' enable debug mode, root account will have password 'hadoop'"
      echo
      echo "You shouldn't specify hadoop version and image type for spark plugin"
      echo "You shouldn't specify image type for hdp plugin"
      echo "Version 'plain' could be specified for hdp plugin only"
      echo "Debug mode should only be enabled for local debugging purposes, not for production systems"
      echo "By default all images for all plugins will be created"
      echo
      exit 1
    ;;
  esac
done

if [ -e /etc/os-release ]; then
  platform=$(head -1 /etc/os-release)
else
  platform=$(head -1 /etc/system-release | grep -e CentOS -e 'Red Hat Enterprise Linux' || :)
  if [ -z "$platform" ]; then
    echo -e "Unknown Host OS. Impossible to build images.\nAborting"
    exit 2
  fi
fi

# Checks of input
if [ "$DEBUG_MODE" = "true" -a "$platform" != 'NAME="Ubuntu"' ]; then
  if [ "$(getenforce)" != "Disabled" ]; then
    echo "Debug mode cannot be used from this platform while SELinux is enabled, see https://bugs.launchpad.net/sahara/+bug/1292614"
    exit 1
  fi
fi

if [ -n "$PLUGIN" -a "$PLUGIN" != "vanilla" -a "$PLUGIN" != "spark" -a "$PLUGIN" != "hdp" ]; then
  echo -e "Unknown plugin selected.\nAborting"
  exit 1
fi

if [ -n "$IMAGE_TYPE" -a "$IMAGE_TYPE" != "ubuntu" -a "$IMAGE_TYPE" != "fedora" -a "$IMAGE_TYPE" != "centos" ]; then
  echo -e "Unknown image type selected.\nAborting"
  exit 1
fi

if [ -n "$HADOOP_VERSION" -a "$HADOOP_VERSION" != "1" -a "$HADOOP_VERSION" != "2" -a "$HADOOP_VERSION" != "plain" ]; then
  echo -e "Unknown hadoop version selected.\nAborting"
  exit 1
fi

if [ "$PLUGIN" = "vanilla" -a "$HADOOP_VERSION" = "plain" ]; then
  echo "Impossible combination.\nAborting"
  exit 1
fi

#################

if [ "$platform" = 'NAME="Ubuntu"' ]; then
  apt-get update -y
  apt-get install qemu kpartx git -y
elif [ "$platform" = 'NAME=Fedora' ]; then
  yum update -y
  yum install qemu kpartx git -y
else
  # centos or rhel
  yum update -y
  yum install qemu-kvm qemu-img kpartx git -y
  if [ ${platform:0:6} = "CentOS" ]; then
    # install EPEL repo, in order to install argparse
    sudo rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/6/i386/epel-release-6-8.noarch.rpm
    # CentOS requires the python-argparse package be installed separately
    yum install python-argparse -y
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

# sahara-image-elements repo

if [ -z $SIM_REPO_PATH ]; then
  SIM_REPO_PATH="$(dirname $base_dir)"
  if [ $(basename $SIM_REPO_PATH) != "sahara-image-elements" ]; then
    echo "Can't find Sahara-image-elements repository. Cloning it."
    git clone https://git.openstack.org/openstack/sahara-image-elements
    SIM_REPO_PATH="$(pwd)/sahara-image-elements"
  fi
fi

ELEMENTS_PATH=$ELEMENTS_PATH:$SIM_REPO_PATH/elements

pushd $SIM_REPO_PATH
export SAHARA_ELEMENTS_COMMIT_ID=`git rev-parse HEAD`
popd

if [ "$DEBUG_MODE" = "true" ]; then
    echo "Using Image Debug Mode, using root-pwd in images, NOT FOR PRODUCTION USAGE."
    # Each image has a root login, password is "hadoop"
    export DIB_PASSWORD="hadoop"
fi

#############################
# Images for Vanilla plugin #
#############################

if [ -z "$PLUGIN" -o "$PLUGIN" = "vanilla" ]; then
  export JAVA_DOWNLOAD_URL=${JAVA_DOWNLOAD_URL:-"http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.tar.gz"}
  export OOZIE_HADOOP_V1_DOWNLOAD_URL=${OOZIE_HADOOP_V1_DOWNLOAD_URL:-"http://sahara-files.mirantis.com/oozie-4.0.0.tar.gz"}
  export OOZIE_HADOOP_V2_DOWNLOAD_URL=${OOZIE_HADOOP_V2_DOWNLOAD_URL:-"http://sahara-files.mirantis.com/oozie-4.0.0-hadoop-2.3.0.tar.gz"}
  export HADOOP_V2_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V2_NATIVE_LIBS_DOWNLOAD_URL:-"http://sahara-files.mirantis.com/hadoop-2.3.0-native-libs.tar.gz"}
  export EXTJS_DOWNLOAD_URL=${EXTJS_DOWNLOAD_URL:-"http://extjs.com/deploy/ext-2.2.zip"}
  export HIVE_VERSION=${HIVE_VERSION:-"0.11.0"}

  ubuntu_elements_sequence="base vm ubuntu hadoop oozie mysql hive"
  fedora_elements_sequence="base vm fedora hadoop oozie mysql hive disable-firewall"
  centos_elements_sequence="vm rhel hadoop oozie mysql hive redhat-lsb disable-firewall"

  if [ "$DEBUG_MODE" = "true" ]; then
    ubuntu_elements_sequence="$ubuntu_elements_sequence root-passwd"
    fedora_elements_sequence="$fedora_elements_sequence root-passwd"
    centos_elements_sequence="$centos_elements_sequence root-passwd"
  fi

  # Workaround for https://bugs.launchpad.net/diskimage-builder/+bug/1204824
  # https://bugs.launchpad.net/sahara/+bug/1252684
  if [ "$platform" = 'NAME="Ubuntu"' ]; then
    echo "**************************************************************"
    echo "WARNING: As a workaround for DIB bug 1204824, you are about to"
    echo "         create a Fedora and CentOS images that has SELinux    "
    echo "         disabled. Do not use these images in production.       "
    echo "**************************************************************"
    fedora_elements_sequence="$fedora_elements_sequence selinux-permissive"
    centos_elements_sequence="$centos_elements_sequence selinux-permissive"
    suffix=".selinux-permissive"
  fi

  if [ -n "$USE_MIRRORS" ]; then
    mirror_element=" apt-mirror"
    ubuntu_elements_sequence=$ubuntu_elements_sequence$mirror_element
    mirror_element=" yum-mirror"
    fedora_elements_sequence=$fedora_elements_sequence$mirror_element
  fi

  # Ubuntu cloud image
  if [ -z "$IMAGE_TYPE" -o "$IMAGE_TYPE" = "ubuntu" ]; then
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "1" ]; then
      export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_1:-"1.2.1"}
      export ubuntu_image_name=${ubuntu_vanilla_hadoop_1_image_name:-"ubuntu_sahara_vanilla_hadoop_1_latest"}
      elements_sequence="$ubuntu_elements_sequence swift_hadoop"
      disk-image-create $elements_sequence -o $ubuntu_image_name
      mv $ubuntu_image_name.qcow2 ../
    fi
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2" ]; then
      export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2:-"2.3.0"}
      export ubuntu_image_name=${ubuntu_vanilla_hadoop_2_image_name:-"ubuntu_sahara_vanilla_hadoop_2_latest"}
      disk-image-create $ubuntu_elements_sequence -o $ubuntu_image_name
      mv $ubuntu_image_name.qcow2 ../
    fi
  fi

  # Fedora cloud image
  if [ -z "$IMAGE_TYPE" -o "$IMAGE_TYPE" = "fedora" ]; then
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "1" ]; then
      export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_1:-"1.2.1"}
      export fedora_image_name=${fedora_vanilla_hadoop_1_image_name:-"fedora_sahara_vanilla_hadoop_1_latest$suffix"}
      elements_sequence="$fedora_elements_sequence swift_hadoop"
      disk-image-create $elements_sequence -o $fedora_image_name
      mv $fedora_image_name.qcow2 ../
    fi
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2" ]; then
      export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2:-"2.3.0"}
      export fedora_image_name=${fedora_vanilla_hadoop_2_image_name:-"fedora_sahara_vanilla_hadoop_2_latest$suffix"}
      disk-image-create $fedora_elements_sequence -o $fedora_image_name
      mv $fedora_image_name.qcow2 ../
    fi
  fi

  # CentOS cloud image:
  # - Disable including 'base' element for CentOS
  # - Export link and filename for CentOS cloud image to download
  # - Patameter 'DIB_IMAGE_SIZE' should be specified for CentOS only
  if [ -z "$IMAGE_TYPE" -o "$IMAGE_TYPE" = "centos" ]; then
    export DIB_IMAGE_SIZE=${IMAGE_SIZE:-"10"}
    # Read Create_CentOS_cloud_image.rst to know how to create CentOS image in qcow2 format
    export BASE_IMAGE_FILE="CentOS-6.5-cloud-init.qcow2"
    export DIB_CLOUD_IMAGES="http://sahara-files.mirantis.com"
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "1" ]; then
      export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_1:-"1.2.1"}
      export centos_image_name=${centos_vanilla_hadoop_1_image_name:-"centos_sahara_vanilla_hadoop_1_latest$suffix"}
      elements_sequence="$centos_elements_sequence swift_hadoop"
      disk-image-create $elements_sequence -n -o $centos_image_name
      mv $centos_image_name.qcow2 ../
    fi
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2" ]; then
      export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2:-"2.3.0"}
      export centos_image_name=${centos_vanilla_hadoop_2_image_name:-"centos_sahara_vanilla_hadoop_2_latest$suffix"}
      disk-image-create $centos_elements_sequence -n -o $centos_image_name
      mv $centos_image_name.qcow2 ../
    fi
  fi
fi

##########################
# Image for Spark plugin #
##########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "spark" ]; then
  # Ignoring image type and hadoop version options
  echo "For spark plugin options -i and -v are ignored"

  export JAVA_DOWNLOAD_URL=${JAVA_DOWNLOAD_URL:-"http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.tar.gz"}
  export DIB_HADOOP_VERSION="CDH4"
  unset DIB_IMAGE_SIZE
  export ubuntu_image_name=${ubuntu_spark_image_name:-"ubuntu_sahara_spark_latest"}

  ubuntu_elements_sequence="base vm ubuntu java hadoop-cdh spark"

  if [ -n "$USE_MIRRORS" ]; then
    mirror_element=" apt-mirror"
    ubuntu_elements_sequence=$ubuntu_elements_sequence$mirror_element
  fi

  # Creating Ubuntu cloud image
  disk-image-create $ubuntu_elements_sequence -o $ubuntu_image_name
  mv $ubuntu_image_name.qcow2 ../
fi

#########################
# Images for HDP plugin #
#########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "hdp" ]; then
  echo "For hdp plugin option -i is ignored"

  # Generate HDP images

  # Parameter 'DIB_IMAGE_SIZE' should be specified for CentOS only
  export DIB_IMAGE_SIZE=${IMAGE_SIZE:-"10"}

  # CentOS cloud image:
  # - Disable including 'base' element for CentOS
  # - Export link and filename for CentOS cloud image to download
  export BASE_IMAGE_FILE="CentOS-6.4-cloud-init.qcow2"
  export DIB_CLOUD_IMAGES="http://sahara-files.mirantis.com"

  # Ignoring image type option
  if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "1" ]; then
    export centos_image_name_hdp_1_3=${centos_hdp_hadoop_1_image_name:-"centos-6_4-64-hdp-1-3"}
    # Elements to include in an HDP-based image
    centos_elements_sequence="vm rhel hadoop-hdp disable-firewall redhat-lsb sahara-version source-repositories yum"
    if [ "$DEBUG_MODE" = "true" ]; then
        # enable the root-pwd element, for simpler local debugging of images
        centos_elements_sequence=$centos_elements_sequence" root-passwd"
    fi

    # generate image with HDP 1.3
    export DIB_HDP_VERSION="1.3"
    disk-image-create $centos_elements_sequence -n -o $centos_image_name_hdp_1_3
    mv $centos_image_name_hdp_1_3.qcow2 ../
  fi

  if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2" ]; then
    export centos_image_name_hdp_2_0=${centos_hdp_hadoop_2_image_name:-"centos-6_4-64-hdp-2-0"}
    # Elements to include in an HDP-based image
    centos_elements_sequence="vm rhel hadoop-hdp disable-firewall redhat-lsb sahara-version source-repositories yum"
    if  [ "$DEBUG_MODE" = "true" ]; then
        # enable the root-pwd element, for simpler local debugging of images
        centos_elements_sequence=$centos_elements_sequence" root-passwd"
    fi

    # generate image with HDP 2.0
    export DIB_HDP_VERSION="2.0"
    disk-image-create $centos_elements_sequence -n -o $centos_image_name_hdp_2_0
    mv $centos_image_name_hdp_2_0.qcow2 ../
  fi

  if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "plain" ]; then
    export centos_image_name_plain=${centos_hdp_plain_image_name:-"centos-6_4-64-plain"}
    # Elements for a plain CentOS image that does not contain HDP or Apache Hadoop
    centos_plain_elements_sequence="vm rhel redhat-lsb disable-firewall ssh sahara-version yum"
    if [ "$DEBUG_MODE" = "true" ]; then
        # enable the root-pwd element, for simpler local debugging of images
        centos_plain_elements_sequence=$centos_plain_elements_sequence" root-passwd"
    fi

    # generate plain (no Hadoop components) image for testing
    disk-image-create $centos_plain_elements_sequence -n -o $centos_image_name_plain
    mv $centos_image_name_plain.qcow2 ../
  fi
fi

popd # out of $TEMP
rm -rf $TEMP
