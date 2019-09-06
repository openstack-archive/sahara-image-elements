#!/bin/bash

set -e

export IMAGE_SIZE=$DIB_IMAGE_SIZE
# This will unset parameter DIB_IMAGE_SIZE for Ubuntu and Fedora vanilla images
unset DIB_IMAGE_SIZE

# DEBUG_MODE is set by the -d flag, debug is enabled if the value is "true"
DEBUG_MODE="false"

# The default version for a MapR plugin
DIB_DEFAULT_MAPR_VERSION="5.2.0"

# The default version for Spark plugin
DIB_DEFAULT_SPARK_VERSION="2.3.0"

# The default version for Storm plugin
DIB_DEFAULT_STORM_VERSION="1.2.1"

# Bare metal image generation is enabled with the -b flag, it is off by default
SIE_BAREMETAL="false"

# Default list of datasource modules for ubuntu. Workaround for bug #1375645
export CLOUD_INIT_DATASOURCES=${DIB_CLOUD_INIT_DATASOURCES:-"NoCloud, ConfigDrive, OVF, MAAS, Ec2"}

# Tracing control
TRACING=

usage() {
    echo
    echo "Usage: $(basename $0)"
    echo "         [-p vanilla|spark|cloudera|storm|mapr|ambari|plain]"
    echo "         [-i ubuntu|fedora|centos7]"
    echo "         [-v 2.7.1|2.7.5|2.8.2|3.0.1|5.5|5.7|5.9|5.11|2.2.0.0|2.2.1.0|2.4.2.0]"
    echo "         [-r 5.1.0|5.2.0]"
    echo "         [-s 1.6.0|2.1.0|2.2.0|2.3.0]"
    echo "         [-t 1.0.1|1.1.0|1.1.1|1.2.0|1.2.1]"
    echo "         [-f qcow2|raw]"
    echo "         [-d]"
    echo "         [-u]"
    echo "         [-j openjdk|oracle-java]"
    echo "         [-x]"
    echo "         [-h]"
    echo "   '-p' is plugin version (default: all plugins)"
    echo "   '-i' is operating system of the base image (default: all non-deprecated"
    echo "        by plugin)."
    echo "   '-v' is hadoop version (default: all supported by plugin)"
    echo "   '-r' is MapR Version (default: ${DIB_DEFAULT_MAPR_VERSION})"
    echo "   '-s' is Spark version (default: ${DIB_DEFAULT_SPARK_VERSION})"
    echo "   '-f' is the image format (default: qcow2)"
    echo "   '-d' enable debug mode, root account will have password 'hadoop'"
    echo "   '-u' install missing packages necessary for building"
    echo "   '-j' is java distribution (default: openjdk)"
    echo "   '-x' turns on tracing"
    echo "   '-b' generate a bare metal image"
    echo "   '-h' display this message"
    echo
    echo "You shouldn't specify image type for spark plugin"
    echo "You shouldn't specify hadoop version for plain images"
    echo "Debug mode should only be enabled for local debugging purposes, not for production systems"
    echo "By default all images for all plugins will be created"
    echo
}

while getopts "p:i:v:f:dur:s:t:j:xhb" opt; do
    case $opt in
        p)
            PLUGIN=$OPTARG
        ;;
        i)
            BASE_IMAGE_OS=$OPTARG
        ;;
        v)
            HADOOP_VERSION=$OPTARG
        ;;
        d)
            DEBUG_MODE="true"
        ;;
        r)
            DIB_MAPR_VERSION=$OPTARG
        ;;
        s)
            DIB_SPARK_VERSION=$OPTARG
        ;;
        t)
            DIB_STORM_VERSION=$OPTARG
        ;;
        f)
            IMAGE_FORMAT="-t $OPTARG"
        ;;
        u)
            DIB_UPDATE_REQUESTED=true
        ;;
        j)
            JAVA_ELEMENT=$OPTARG
        ;;
        x)
            TRACING="$TRACING -x"
            set -x
        ;;
        b)
            SIE_BAREMETAL="true"
        ;;
        h)
            usage
            exit 0
        ;;
        *)
            usage
            exit 1
        ;;
    esac
done

shift $((OPTIND-1))
if [ "$1" ]; then
    usage
    exit 1
fi

JAVA_ELEMENT=${JAVA_ELEMENT:-"openjdk"}

if [ -e /etc/os-release ]; then
    platform=$(cat /etc/os-release | awk -F= '/^ID=/ {print tolower($2);}')
    # remove eventual quotes around ID=...
    platform=$(echo $platform | sed -e 's,^",,;s,"$,,')
elif [ -e /etc/system-release ]; then
    case "$(head -1 /etc/system-release)" in
        "Red Hat Enterprise Linux Server"*)
            platform=rhel
            ;;
        "CentOS"*)
            platform=centos
            ;;
        *)
            echo -e "Unknown value in /etc/system-release. Impossible to build images.\nAborting"
            exit 2
            ;;
    esac
else
    echo -e "Unknown host OS. Impossible to build images.\nAborting"
    exit 2
fi

# Checks of input
if [ "$DEBUG_MODE" = "true" -a "$platform" != 'ubuntu' ]; then
    if [ "$(getenforce)" != "Disabled" ]; then
        echo "Debug mode cannot be used from this platform while SELinux is enabled, see https://storyboard.openstack.org/#!/story/1292614"
        exit 1
    fi
fi

check_spark_version () {
    case "$DIB_SPARK_VERSION" in
        "1.6.0" | "2.1.0" | "2.2.0" | "2.3.0");;
        "")
            echo "Spark version not specified"
            echo "Spark ${DIB_DEFAULT_SPARK_VERSION} will be used"
            DIB_SPARK_VERSION=${DIB_DEFAULT_SPARK_VERSION}
        ;;
        *)
            echo -e "Unknown Spark version selected.\nAborting"
            exit 1
        ;;
    esac
}

case "$PLUGIN" in
    "");;
    "vanilla")
        case "$HADOOP_VERSION" in
            "" | "2.7.1" | "2.7.5" | "2.8.2" | "3.0.1");;
            *)
                echo -e "Unknown hadoop version selected.\nAborting"
                exit 1
            ;;
        esac
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "fedora" | "centos7");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac
        check_spark_version
        ;;
    "cloudera")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "centos7");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac

        case "$HADOOP_VERSION" in
            "" | "5.5" | "5.7" | "5.9" | "5.11");;
            *)
                echo -e "Unknown hadoop version selected.\nAborting"
                exit 1
            ;;
        esac

        if [ "$BASE_IMAGE_OS" = "centos7"  ]; then
            if [ ! -z "$HADOOP_VERSION" -a ! "$HADOOP_VERSION" = "5.5"  -a ! "$HADOOP_VERSION" = "5.7" -a ! "$HADOOP_VERSION" = "5.9" -a ! "$HADOOP_VERSION" = "5.11" ]; then
                echo -e "Unsupported version combination, Centos 7 can only be used with CDH 5.5 or higher version"
                exit 1
            fi
        fi

        if [ -n "$DIB_CDH_MINOR_VERSION" ]; then
            echo -e "Continuing image building with custom CDH version: \"$DIB_CDH_MINOR_VERSION\".\n"
        fi
        ;;
    "spark")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac
        check_spark_version
        ;;
    "storm")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac

        case "$DIB_STORM_VERSION" in
            "1.0.1" | "1.1.0" | "1.1.1" | "1.2.0" | "1.2.1");;
            "")
                echo "Storm version not specified"
                echo "Storm ${DIB_DEFAULT_STORM_VERSION} will be used"
                DIB_STORM_VERSION=${DIB_DEFAULT_STORM_VERSION}
            ;;
            *)
                echo -e "Unknown Storm version selected.\nAborting"
                exit 1
            ;;
        esac

        if [ -n "$HADOOP_VERSION" ]; then
            echo -e "You shouldn't specify hadoop version for '$PLUGIN'.\nAborting"
            exit 1
        fi
        ;;
    "ambari")
        case "$BASE_IMAGE_OS" in
            "" | "centos7" | "ubuntu" )
            ;;
            * )
                echo "\"$BASE_IMAGE_OS\" image type is not supported by \"$PLUGIN\".\nAborting"
                exit 1
            ;;
        esac

        case "$HADOOP_VERSION" in
            "" | "2.2.0.0" | "2.2.1.0" | "2.4.2.0");;
            *)
                echo -e "Continuing image building with custom ambari version \"$HADOOP_VERSION\"\n"
            ;;
        esac
        ;;
    "mapr")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "centos7");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac

        if [ -n "$HADOOP_VERSION" ]; then
            echo -e "You shouldn't specify hadoop version for 'mapr'.\nAborting"
            exit 1
        fi

        case "$DIB_MAPR_VERSION" in
            "")
                echo "MapR version is not specified"
                echo "${DIB_DEFAULT_MAPR_VERSION} version would be used"
                DIB_MAPR_VERSION=${DIB_DEFAULT_MAPR_VERSION}
            ;;
            "5.1.0" | "5.2.0");;
            *)
                echo -e "Unknown MapR version.\nExit"
                exit 1
            ;;
        esac
        ;;
    "plain")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "fedora" | "centos7");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac

        if [ -n "$HADOOP_VERSION" ]; then
            echo -e "You shouldn't specify hadoop version for '$PLUGIN'.\nAborting"
            exit 1
        fi
        ;;
    *)
        echo -e "Unknown plugin selected.\nAborting"
        exit 1
esac

if [ "$PLUGIN" != "mapr" -a -n "$DIB_MAPR_VERSION" ]; then
    echo -e "'-r' parameter should be used only with 'mapr' plugin.\nAborting"
    exit 1
fi


if [ "$JAVA_ELEMENT" != "openjdk" -a "$JAVA_ELEMENT" != "oracle-java" ]; then
    echo "Unknown java distro"
    exit 1
fi

#################

is_installed() {
    if [ "$platform" = 'ubuntu' -o "$platform" = 'debian' ]; then
        dpkg -s "$1" &> /dev/null
    else
        # centos, fedora, opensuse, or rhel
        if ! rpm -q "$1" &> /dev/null; then
            rpm -q "$(rpm -q --whatprovides "$1")"
        fi
    fi
}

need_required_packages() {
    case "$platform" in
        "ubuntu" | "debian")
            package_list="qemu-utils kpartx git"
            ;;
        "fedora")
            package_list="qemu-img kpartx git"
            ;;
        "opensuse")
            package_list="qemu kpartx git-core"
            ;;
        "rhel" | "centos")
            package_list="qemu-kvm qemu-img kpartx git"
            ;;
        *)
            echo -e "Unknown platform '$platform' for the package list.\nAborting"
            exit 2
            ;;
    esac

    for p in `echo $package_list`; do
        if ! is_installed $p; then
            echo "Package $p is not installed on the system."
            return 0
        fi
    done
    return 1
}

if need_required_packages; then
    # install required packages if requested
    if [ -n "$DIB_UPDATE_REQUESTED" ]; then
        case "$platform" in
            "ubuntu" | "debian")
                sudo apt-get update
                sudo apt-get install $package_list -y
                ;;
            "opensuse")
                sudo zypper --non-interactive --gpg-auto-import-keys in $package_list
                ;;
            *)
                echo -e "Unknown platform '$platform' for installing packages.\nAborting"
                exit 2
                ;;
        esac
    else
        echo "Missing one of the following packages: $package_list"
        echo "Please install manually or rerun with the update option (-u)."
        exit 1
    fi
fi

if [ "$DEBUG_MODE" = "true" ]; then
    echo "Using Image Debug Mode, using root-pwd in images, NOT FOR PRODUCTION USAGE."
    # Each image has a root login, password is "hadoop"
    export DIB_PASSWORD="hadoop"
fi

#################

# Common helper for invoking disk-image-create, adding all the common
# elements and arguments, and setting common environment variables.
#
# Usage:
#   image_create DISTRO OUTPUT [args...]
# - DISTRO is the main element of the distribution
# - OUTPUT is the output name for the image
# - any other argument is passed directly to disk-image-create
image_create() {
    local distro=$1
    shift
    local output=$1
    shift

    # the base elements and args, used in *all* the images
    local elements="sahara-version ntp xfs-tools"
    if [ $SIE_BAREMETAL = "true" ]; then
        elements="grub2 baremetal dhcp-all-interfaces $elements"
    else
        elements="vm $elements"
    fi
    local args=""

    # debug mode handling
    if [ "$DEBUG_MODE" = "true" ]; then
        elements="$elements root-passwd"
    fi
    # mirror handling
    if [ -n "$USE_MIRRORS" ]; then
        case "$distro" in
            ubuntu) elements="$elements apt-mirror" ;;
            fedora) elements="$elements fedora-mirror" ;;
            centos7) elements="$elements centos-mirror" ;;
        esac
    fi

    disk-image-create $IMAGE_FORMAT $TRACING -o "$output" $args "$distro" $elements "$@"
}

set_hive_version() {
    if [ -z "${HIVE_VERSION:-}" ]; then
        case "$DIB_HADOOP_VERSION" in
            "2.7.1" )
                export HIVE_VERSION="0.11.0"
            ;;
            "2.7.5" )
                export HIVE_VERSION="2.3.2"
            ;;
            "2.8.2" )
                export HIVE_VERSION="2.3.2"
            ;;
            "3.0.1" )
                export HIVE_VERSION="3.0.0"
            ;;
            *)
                echo -e "Unknown Hadoop version, therefore cannot choose Hive version.\nAborting."
                exit 1
            ;;
        esac
    fi
}


#############################
# Images for Vanilla plugin #
#############################

if [ -z "$PLUGIN" -o "$PLUGIN" = "vanilla" ]; then
    export HADOOP_V2_7_1_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V2_7_1_NATIVE_LIBS_DOWNLOAD_URL:-"https://tarballs.openstack.org/sahara-extra/dist/common-artifacts/hadoop-native-libs-2.7.1.tar.gz"}
    export HADOOP_V2_7_5_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V2_7_5_NATIVE_LIBS_DOWNLOAD_URL:-"https://tarballs.openstack.org/sahara-extra/dist/common-artifacts/hadoop-native-libs-2.7.5.tar.gz"}
    export HADOOP_V2_8_2_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V2_8_2_NATIVE_LIBS_DOWNLOAD_URL:-"https://tarballs.openstack.org/sahara-extra/dist/common-artifacts/hadoop-native-libs-2.8.2.tar.gz"}
    export HADOOP_V3_0_1_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V3_0_1_NATIVE_LIBS_DOWNLOAD_URL:-"https://tarballs.openstack.org/sahara-extra/dist/common-artifacts/hadoop-native-libs-3.0.1.tar.gz"}
    export OOZIE_HADOOP_V2_7_1_DOWNLOAD_URL=${OOZIE_HADOOP_V2_7_1_FILE:-"https://tarballs.openstack.org/sahara-extra/dist/oozie/oozie-4.2.0-hadoop-2.7.1.tar.gz"}
    export OOZIE_HADOOP_V2_7_5_DOWNLOAD_URL=${OOZIE_HADOOP_V2_7_5_FILE:-"https://tarballs.openstack.org/sahara-extra/dist/oozie/oozie-4.3.0-hadoop-2.7.5.tar.gz"}
    export OOZIE_HADOOP_V2_8_2_DOWNLOAD_URL=${OOZIE_HADOOP_V2_8_2_FILE:-"https://tarballs.openstack.org/sahara-extra/dist/oozie/oozie-4.3.0-hadoop-2.8.2.tar.gz"}
    export OOZIE_HADOOP_V3_0_1_DOWNLOAD_URL=${OOZIE_HADOOP_V3_0_1_FILE:-"https://tarballs.openstack.org/sahara-extra/dist/oozie/oozie-5.0.0-hadoop-3.0.1.tar.gz"}
    export DIB_HDFS_LIB_DIR="/opt/hadoop/share/hadoop/tools/lib"
    export plugin_type="vanilla"

    export DIB_SPARK_VERSION

    if [ "$DIB_SPARK_VERSION" = "1.6.0" ]; then
        export SPARK_HADOOP_DL=hadoop2.6
    else
        export SPARK_HADOOP_DL=hadoop2.7
    fi

    ubuntu_elements_sequence="hadoop oozie mysql hive $JAVA_ELEMENT swift_hadoop spark s3_hadoop"
    fedora_elements_sequence="hadoop oozie mysql disable-firewall hive $JAVA_ELEMENT swift_hadoop spark s3_hadoop"
    centos7_elements_sequence="hadoop oozie mysql disable-firewall hive $JAVA_ELEMENT swift_hadoop spark nc s3_hadoop"

    # Workaround for https://bugs.launchpad.net/diskimage-builder/+bug/1204824
    # https://storyboard.openstack.org/#!/story/1252684
    if [ "$platform" = 'ubuntu' ]; then
        echo "**************************************************************"
        echo "WARNING: As a workaround for DIB bug 1204824, you are about to"
        echo "         create a Fedora and CentOS images that has SELinux    "
        echo "         disabled. Do not use these images in production.       "
        echo "**************************************************************"
        fedora_elements_sequence="$fedora_elements_sequence selinux-permissive"
        centos7_elements_sequence="$centos7_elements_sequence selinux-permissive"
        suffix=".selinux-permissive"
    fi
    # Ubuntu cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES

        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export ubuntu_image_name=${ubuntu_vanilla_hadoop_2_7_1_image_name:-"ubuntu_sahara_vanilla_hadoop_2_7_1_latest"}
            export DIB_RELEASE=${DIB_RELEASE:-xenial}
            set_hive_version
            image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
            unset DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.5" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_5:-"2.7.5"}
            export ubuntu_image_name=${ubuntu_vanilla_hadoop_2_7_5_image_name:-"ubuntu_sahara_vanilla_hadoop_2_7_5_latest"}
            export DIB_RELEASE=${DIB_RELEASE:-xenial}
            set_hive_version
            image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
            unset DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.8.2" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_8_2:-"2.8.2"}
            export ubuntu_image_name=${ubuntu_vanilla_hadoop_2_8_2_image_name:-"ubuntu_sahara_vanilla_hadoop_2_8_2_latest"}
            export DIB_RELEASE=${DIB_RELEASE:-xenial}
            set_hive_version
            image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
            unset DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "3.0.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_3_0_1:-"3.0.1"}
            export ubuntu_image_name=${ubuntu_vanilla_hadoop_3_0_1_image_name:-"ubuntu_sahara_vanilla_hadoop_3_0_1_latest"}
            export DIB_RELEASE=${DIB_RELEASE:-xenial}
            set_hive_version
            image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
            unset DIB_RELEASE
        fi
        unset DIB_CLOUD_INIT_DATASOURCES
    fi

    # Fedora cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "fedora" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export fedora_image_name=${fedora_vanilla_hadoop_2_7_1_image_name:-"fedora_sahara_vanilla_hadoop_2_7_1_latest$suffix"}
            set_hive_version
            image_create fedora $fedora_image_name $fedora_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.5" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_5:-"2.7.5"}
            export fedora_image_name=${fedora_vanilla_hadoop_2_7_5_image_name:-"fedora_sahara_vanilla_hadoop_2_7_5_latest$suffix"}
            set_hive_version
            image_create fedora $fedora_image_name $fedora_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.8.2" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_8_2:-"2.8.2"}
            export fedora_image_name=${fedora_vanilla_hadoop_2_8_2_image_name:-"fedora_sahara_vanilla_hadoop_2_8_2_latest$suffix"}
            set_hive_version
            image_create fedora $fedora_image_name $fedora_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "3.0.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_3_0_1:-"3.0.1"}
            export fedora_image_name=${fedora_vanilla_hadoop_3_0_1_image_name:-"fedora_sahara_vanilla_hadoop_3_0_1_latest$suffix"}
            set_hive_version
            image_create fedora $fedora_image_name $fedora_elements_sequence
        fi
    fi

    # CentOS 7 cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export centos7_image_name=${centos7_vanilla_hadoop_2_7_1_image_name:-"centos7_sahara_vanilla_hadoop_2_7_1_latest$suffix"}
            set_hive_version
            image_create centos7 $centos7_image_name $centos7_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.5" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_5:-"2.7.5"}
            export centos7_image_name=${centos7_vanilla_hadoop_2_7_5_image_name:-"centos7_sahara_vanilla_hadoop_2_7_5_latest$suffix"}
            set_hive_version
            image_create centos7 $centos7_image_name $centos7_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.8.2" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_8_2:-"2.8.2"}
            export centos7_image_name=${centos7_vanilla_hadoop_2_8_2_image_name:-"centos7_sahara_vanilla_hadoop_2_8_2_latest$suffix"}
            set_hive_version
            image_create centos7 $centos7_image_name $centos7_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "3.0.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_3_0_1:-"3.0.1"}
            export centos7_image_name=${centos7_vanilla_hadoop_3_0_1_image_name:-"centos7_sahara_vanilla_hadoop_3_0_1_latest$suffix"}
            set_hive_version
            image_create centos7 $centos7_image_name $centos7_elements_sequence
        fi
    fi

    unset plugin_type
    unset DIB_HDFS_LIB_DIR
    unset DIB_SPARK_VERSION
    unset SPARK_HADOOP_DL
fi

###########################
# Images for Spark plugin #
###########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "spark" ]; then
    export DIB_HDFS_LIB_DIR="/usr/lib/hadoop-mapreduce"
    export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES
    export DIB_SPARK_VERSION
    export plugin_type="spark"

    if [ "$DIB_SPARK_VERSION" = "2.2.0" -o "$DIB_SPARK_VERSION" = "2.3.0" ]; then
        export DIB_CDH_VERSION="5.11"
        export DIB_RELEASE=${DIB_RELEASE:-xenial}
    else
        export DIB_RELEASE=${DIB_RELEASE:-trusty}
        export DIB_CDH_VERSION="5.5"
    fi
    if [ "$DIB_SPARK_VERSION" = "1.6.0" ]; then
        export SPARK_HADOOP_DL=hadoop2.6
    else
        export SPARK_HADOOP_DL=hadoop2.7
    fi
    # Tell the cloudera element to install only hdfs
    export DIB_CDH_HDFS_ONLY=1

    ubuntu_elements_sequence="$JAVA_ELEMENT swift_hadoop spark hadoop-cloudera s3_hadoop"
    export ubuntu_image_name=${ubuntu_spark_image_name:-"ubuntu_sahara_spark_latest"}

    # Creating Ubuntu cloud image
    image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
    unset SPARK_HADOOP_DL
    unset DIB_CLOUD_INIT_DATASOURCES
    unset DIB_HDFS_LIB_DIR
    unset DIB_CDH_HDFS_ONLY
    unset DIB_CDH_VERSION
    unset DIB_SPARK_VERSION
    unset DIB_HADOOP_VERSION
    unset DIB_RELEASE
    unset plugin_type
fi


##########################
# Image for Storm plugin #
##########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "storm" ]; then
    export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES

    export DIB_STORM_VERSION
    export ubuntu_image_name=${ubuntu_storm_image_name:-"ubuntu_sahara_storm_latest_$DIB_STORM_VERSION"}

    ubuntu_elements_sequence="$JAVA_ELEMENT zookeeper storm"

    # Creating Ubuntu cloud image
    export DIB_RELEASE=${DIB_RELEASE:-xenial}
    image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
    unset DIB_RELEASE
    unset DIB_CLOUD_INIT_DATASOURCES
fi

############################
# Images for Ambari plugin #
############################

if [ -z "$PLUGIN" -o "$PLUGIN" = "ambari" ]; then
    export DIB_AMBARI_VERSION="$HADOOP_VERSION"
    export plugin_type="ambari"
    # set the temporary folder for hadoop-openstack.jar file
    export DIB_HDFS_LIB_DIR="/opt"

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        ambari_ubuntu_image_name=${ambari_ubuntu_image_name:-ubuntu_sahara_ambari}
        ambari_element_sequence="ambari $JAVA_ELEMENT swift_hadoop kdc"
        export DIB_RELEASE="trusty"
        image_create ubuntu $ambari_ubuntu_image_name $ambari_element_sequence
        unset DIB_RELEASE
    fi
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        ambari_centos7_image_name=${ambari_centos7_image_name:-"centos7-sahara-ambari"}
        ambari_element_sequence="disable-selinux ambari $JAVA_ELEMENT disable-firewall swift_hadoop kdc nc"
        image_create centos7 $ambari_centos7_image_name $ambari_element_sequence
    fi

    unset DIB_HDFS_LIB_DIR
    unset plugin_type
    unset DIB_AMBARI_VERSION
fi

#########################
# Images for CDH plugin #
#########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "cloudera" ]; then
    # Cloudera installation requires additional space
    export DIB_MIN_TMPFS=5
    export plugin_type="cloudera"
    export DIB_HDFS_LIB_DIR="/usr/lib/hadoop-mapreduce"

    if [ -n "$DIB_CDH_MINOR_VERSION" ]; then
        # cut minor version number, e.g. from 5.7.1 to  5.7
        # this is needed if user specified minor version but didn't specify
        # hadoop version by '-v' parameter
        HADOOP_VERSION=${DIB_CDH_MINOR_VERSION%.*}
    fi

    cloudera_elements_sequence="hadoop-cloudera swift_hadoop kdc"
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.5" ]; then
            export DIB_CDH_VERSION="5.5"
            cloudera_5_5_ubuntu_image_name=${cloudera_5_5_ubuntu_image_name:-ubuntu_sahara_cloudera_5_5_0}

            # Cloudera supports 14.04 Ubuntu in 5.5
            export DIB_RELEASE="trusty"
            image_create ubuntu $cloudera_5_5_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.7" ]; then
            export DIB_CDH_VERSION="5.7"
            export DIB_CDH_MINOR_VERSION=${DIB_CDH_MINOR_VERSION:-$DIB_CDH_VERSION.0}
            cloudera_5_7_ubuntu_image_name=${cloudera_5_7_ubuntu_image_name:-ubuntu_sahara_cloudera_$DIB_CDH_MINOR_VERSION}

            export DIB_RELEASE="trusty"
            image_create ubuntu $cloudera_5_7_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE DIB_CDH_MINOR_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.9" ]; then
            export DIB_CDH_VERSION="5.9"
            export DIB_CDH_MINOR_VERSION=${DIB_CDH_MINOR_VERSION:-$DIB_CDH_VERSION.0}
            cloudera_5_9_ubuntu_image_name=${cloudera_5_9_ubuntu_image_name:-ubuntu_sahara_cloudera_$DIB_CDH_MINOR_VERSION}

            export DIB_RELEASE="trusty"
            image_create ubuntu $cloudera_5_9_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE DIB_CDH_MINOR_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.11" ]; then
            export DIB_CDH_VERSION="5.11"
            export DIB_CDH_MINOR_VERSION=${DIB_CDH_MINOR_VERSION:-$DIB_CDH_VERSION.0}
            cloudera_5_11_ubuntu_image_name=${cloudera_5_11_ubuntu_image_name:-ubuntu_sahara_cloudera_$DIB_CDH_MINOR_VERSION}

            export DIB_RELEASE="xenial"
            image_create ubuntu $cloudera_5_11_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE DIB_CDH_MINOR_VERSION
        fi
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        centos7_cloudera_elements_sequence="selinux-permissive disable-firewall nc"
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.5" ]; then
            export DIB_CDH_VERSION="5.5"

            cloudera_5_5_centos7_image_name=${cloudera_5_5_centos7_image_name:-centos7_sahara_cloudera_5_5_0}
            image_create centos7 $cloudera_5_5_centos7_image_name $cloudera_elements_sequence $centos7_cloudera_elements_sequence

            unset DIB_CDH_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.7" ]; then
            export DIB_CDH_VERSION="5.7"
            export DIB_CDH_MINOR_VERSION=${DIB_CDH_MINOR_VERSION:-$DIB_CDH_VERSION.0}

            cloudera_5_7_centos7_image_name=${cloudera_5_7_centos7_image_name:-centos7_sahara_cloudera_$DIB_CDH_MINOR_VERSION}
            image_create centos7 $cloudera_5_7_centos7_image_name $cloudera_elements_sequence $centos7_cloudera_elements_sequence

            unset DIB_CDH_VERSION DIB_CDH_MINOR_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.9" ]; then
            export DIB_CDH_VERSION="5.9"
            export DIB_CDH_MINOR_VERSION=${DIB_CDH_MINOR_VERSION:-$DIB_CDH_VERSION.0}

            cloudera_5_9_centos7_image_name=${cloudera_5_9_centos7_image_name:-centos7_sahara_cloudera_$DIB_CDH_MINOR_VERSION}
            image_create centos7 $cloudera_5_9_centos7_image_name $cloudera_elements_sequence $centos7_cloudera_elements_sequence

            unset DIB_CDH_VERSION DIB_CDH_MINOR_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.11" ]; then
            export DIB_CDH_VERSION="5.11"
            export DIB_CDH_MINOR_VERSION=${DIB_CDH_MINOR_VERSION:-$DIB_CDH_VERSION.0}

            cloudera_5_11_centos7_image_name=${cloudera_5_11_centos7_image_name:-centos7_sahara_cloudera_$DIB_CDH_MINOR_VERSION}
            image_create centos7 $cloudera_5_11_centos7_image_name $cloudera_elements_sequence $centos7_cloudera_elements_sequence

            unset DIB_CDH_VERSION DIB_CDH_MINOR_VERSION
        fi
    fi

    unset DIB_CDH_MINOR_VERSION
    unset DIB_HDFS_LIB_DIR
    unset DIB_MIN_TMPFS
    unset plugin_type
fi

##########################
# Images for MapR plugin #
##########################
if [ -z "$PLUGIN" -o "$PLUGIN" = "mapr" ]; then
    export DIB_MAPR_VERSION=${DIB_MAPR_VERSION:-${DIB_DEFAULT_MAPR_VERSION}}
    export plugin_type="mapr"

    export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES

    export DIB_IMAGE_SIZE=${IMAGE_SIZE:-"10"}
    #MapR repository requires additional space
    export DIB_MIN_TMPFS=10

    mapr_ubuntu_elements_sequence="ssh hadoop-mapr $JAVA_ELEMENT"
    mapr_centos_elements_sequence="ssh hadoop-mapr selinux-permissive $JAVA_ELEMENT disable-firewall nc"

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        export DIB_RELEASE=${DIB_RELEASE:-trusty}

        mapr_ubuntu_image_name=${mapr_ubuntu_image_name:-ubuntu_${DIB_RELEASE}_mapr_${DIB_MAPR_VERSION}_latest}

        image_create ubuntu $mapr_ubuntu_image_name $mapr_ubuntu_elements_sequence

        unset DIB_RELEASE
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        mapr_centos7_image_name=${mapr_centos7_image_name:-centos_7_mapr_${DIB_MAPR_VERSION}_latest}

        image_create centos7 $mapr_centos7_image_name $mapr_centos_elements_sequence

        unset DIB_CLOUD_INIT_DATASOURCES
    fi
    unset plugin_type

fi

################
# Plain images #
################
if [ -z "$PLUGIN" -o "$PLUGIN" = "plain" ]; then
    # generate plain (no Hadoop components) images for testing

    common_elements="ssh"

    ubuntu_elements_sequence="$common_elements"
    fedora_elements_sequence="$common_elements"
    centos7_elements_sequence="$common_elements disable-firewall disable-selinux nc"

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        plain_image_name=${plain_ubuntu_image_name:-ubuntu_plain}

        export DIB_RELEASE=${DIB_RELEASE:-xenial}
        image_create ubuntu $plain_image_name $ubuntu_elements_sequence
        unset DIB_RELEASE
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "fedora" ]; then
        plain_image_name=${plain_fedora_image_name:-fedora_plain}

        image_create fedora $plain_image_name $fedora_elements_sequence
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        plain_image_name=${plain_centos7_image_name:-centos7_plain}

        image_create centos7 $plain_image_name $centos7_elements_sequence
    fi
fi
