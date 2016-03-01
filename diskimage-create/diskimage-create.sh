#!/bin/bash

set -e

export IMAGE_SIZE=$DIB_IMAGE_SIZE
# This will unset parameter DIB_IMAGE_SIZE for Ubuntu and Fedora vanilla images
unset DIB_IMAGE_SIZE

# DEBUG_MODE is set by the -d flag, debug is enabled if the value is "true"
DEBUG_MODE="false"

# The default version for a MapR plugin
DIB_DEFAULT_MAPR_VERSION="5.1.0"

# The default version for Spark plugin
DIB_DEFAULT_SPARK_VERSION="1.6.0"

# Bare metal image generation is enabled with the -b flag, it is off by default
SIE_BAREMETAL="false"

# Default list of datasource modules for ubuntu. Workaround for bug #1375645
export CLOUD_INIT_DATASOURCES=${DIB_CLOUD_INIT_DATASOURCES:-"NoCloud, ConfigDrive, OVF, MAAS, Ec2"}

# Tracing control
TRACING=

usage() {
    echo
    echo "Usage: $(basename $0)"
    echo "         [-p vanilla|spark|hdp|cloudera|storm|mapr|ambari|plain]"
    echo "         [-i ubuntu|fedora|centos|centos7]"
    echo "         [-v 2|2.6|2.7.1|4|5.0|5.3|5.4|5.5]"
    echo "         [-r 5.0.0|5.1.0]"
    echo "         [-s 1.3.1|1.6.0]"
    echo "         [-d]"
    echo "         [-u]"
    echo "         [-j openjdk|oracle-java]"
    echo "         [-x]"
    echo "         [-h]"
    echo "   '-p' is plugin version (default: all plugins)"
    echo "   '-i' is operating system of the base image (default: all supported by plugin)"
    echo "   '-v' is hadoop version (default: all supported by plugin)"
    echo "   '-r' is MapR Version (default: ${DIB_DEFAULT_MAPR_VERSION})"
    echo "   '-s' is Spark version (default: ${DIB_DEFAULT_SPARK_VERSION})"
    echo "   '-d' enable debug mode, root account will have password 'hadoop'"
    echo "   '-u' install missing packages necessary for building"
    echo "   '-j' is java distribution (default: openjdk)"
    echo "   '-x' turns on tracing"
    echo "   '-b' generate a bare metal image"
    echo "   '-h' display this message"
    echo
    echo "You shouldn't specify image type for spark plugin"
    echo "You shouldn't specify image type for hdp plugin"
    echo "You shouldn't specify hadoop version for plain images"
    echo "Debug mode should only be enabled for local debugging purposes, not for production systems"
    echo "By default all images for all plugins will be created"
    echo
}

while getopts "p:i:v:dur:s:j:xhb" opt; do
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
        echo "Debug mode cannot be used from this platform while SELinux is enabled, see https://bugs.launchpad.net/sahara/+bug/1292614"
        exit 1
    fi
fi

case "$PLUGIN" in
    "");;
    "vanilla")
        case "$HADOOP_VERSION" in
            "" | "2.6" | "2.7.1");;
            *)
                echo -e "Unknown hadoop version selected.\nAborting"
                exit 1
            ;;
        esac
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "fedora" | "centos" | "centos7");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac
        ;;
    "cloudera")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "centos");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac

        case "$HADOOP_VERSION" in
            "" | "5.0" | "5.3" | "5.4" | "5.5");;
            *)
                echo -e "Unknown hadoop version selected.\nAborting"
                exit 1
            ;;
        esac
        ;;
    "spark")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by '$PLUGIN'.\nAborting"
                exit 1
            ;;
        esac

        case "$HADOOP_VERSION" in
            "")
                echo "CDH version not specified"
                echo "CDH version 5.3 will be used"
                HADOOP_VERSION="5.3"
            ;;
            "4")
                HADOOP_VERSION="CDH4"
            ;;
            "5.0" | "5.3" | "5.4" | "5.5");;
            *)
                echo -e "Unknown hadoop version selected.\nAborting"
                exit 1
            ;;
        esac

        case "$DIB_SPARK_VERSION" in
            "")
                echo "Spark version not specified"
                echo "Spark ${DIB_DEFAULT_SPARK_VERSION} will be used"
                DIB_SPARK_VERSION=${DIB_DEFAULT_SPARK_VERSION}
            ;;
        esac

        ;;
    "storm")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu");;
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
    "hdp")
        case "$BASE_IMAGE_OS" in
            "" | "centos");;
            *)
                echo -e "'$BASE_IMAGE_OS' image type is not supported by 'hdp'.\nAborting"
                exit 1
            ;;
        esac

        case "$HADOOP_VERSION" in
            "" | "1" | "2");;
            *)
                echo -e "Unknown hadoop version selected.\nAborting"
                exit 1
            ;;
        esac
        ;;
    "ambari")
        case "$BASE_IMAGE_OS" in
            "" | "centos" | "centos7" | "ubuntu" )
            ;;
            * )
                echo "\"$BASE_IMAGE_OS\" image type is not supported by \"$PLUGIN\".\nAborting"
                exit 1
            ;;
        esac
    ;;
    "mapr")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "centos");;
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
            "5.0.0" | "5.1.0");;
            *)
                echo -e "Unknown MapR version.\nExit"
                exit 1
            ;;
        esac
        ;;
    "plain")
        case "$BASE_IMAGE_OS" in
            "" | "ubuntu" | "fedora" | "centos" | "centos7");;
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
    if [ "$platform" = 'ubuntu' ]; then
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
        "ubuntu")
            package_list="qemu kpartx git"
            ;;
        "fedora")
            package_list="qemu-img kpartx git"
            ;;
        "opensuse")
            package_list="qemu kpartx git-core"
            ;;
        "rhel" | "centos")
            package_list="qemu-kvm qemu-img kpartx git"
            if [ ${platform} = "centos" ]; then
                # CentOS requires the python-argparse package be installed separately
                package_list="$package_list python-argparse"
            fi
            ;;
        *)
            echo -e "Unknown platform '$platform' for the package list.\nAborting"
            exit 2
            ;;
    esac

    for p in `echo $package_list`; do
        if ! is_installed $p; then
            return 0
        fi
    done
    return 1
}

if need_required_packages; then
    # install required packages if requested
    if [ -n "$DIB_UPDATE_REQUESTED" ]; then
        case "$platform" in
            "ubuntu")
                sudo apt-get update
                sudo apt-get install $package_list -y
                ;;
            "opensuse")
                sudo zypper --non-interactive --gpg-auto-import-keys in $package_list
                ;;
            "fedora" | "rhel" | "centos")
                if [ ${platform} = "centos" ]; then
                    # install EPEL repo, in order to install argparse
                    sudo rpm -Uvh --force http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
                fi
                sudo yum install $package_list -y
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
            centos | centos7) elements="$elements centos-mirror" ;;
        esac
    fi
    # use a custom cloud image for CentOS 6
    case "$distro" in
        centos)
            export BASE_IMAGE_FILE=${BASE_IMAGE_FILE:-"CentOS-6.6-cloud-init-20150821.qcow2"}
            export DIB_CLOUD_IMAGES=${DIB_CLOUD_IMAGES:-"http://sahara-files.mirantis.com"}
        ;;
    esac

    disk-image-create $TRACING -o "$output" $args "$distro" $elements "$@"

    # cleanup
    case "$distro" in
        centos)
            unset BASE_IMAGE_FILE DIB_CLOUD_IMAGES
        ;;
    esac
}

#############################
# Images for Vanilla plugin #
#############################

if [ -z "$PLUGIN" -o "$PLUGIN" = "vanilla" ]; then
    export OOZIE_HADOOP_V2_6_DOWNLOAD_URL=${OOZIE_HADOOP_V2_6_DOWNLOAD_URL:-"http://sahara-files.mirantis.com/oozie-4.0.1-hadoop-2.6.0.tar.gz"}
    export HADOOP_V2_6_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V2_6_NATIVE_LIBS_DOWNLOAD_URL:-"http://sahara-files.mirantis.com/hadoop-native-libs-2.6.0.tar.gz"}
    export HIVE_VERSION=${HIVE_VERSION:-"0.11.0"}
    export HADOOP_V2_7_1_NATIVE_LIBS_DOWNLOAD_URL=${HADOOP_V2_7_1_NATIVE_LIBS_DOWNLOAD_URL:-"http://sahara-files.mirantis.com/hadoop-native-libs-2.7.1.tar.gz"}
    export OOZIE_HADOOP_V2_7_1_DOWNLOAD_URL=${OOZIE_HADOOP_V2_7_1_FILE:-"http://sahara-files.mirantis.com/oozie-4.2.0-hadoop-2.7.1.tar.gz"}

    ubuntu_elements_sequence="hadoop oozie mysql hive $JAVA_ELEMENT"
    fedora_elements_sequence="hadoop oozie mysql disable-firewall hive $JAVA_ELEMENT"
    centos_elements_sequence="hadoop oozie mysql disable-firewall hive $JAVA_ELEMENT"
    centos7_elements_sequence="hadoop oozie mysql disable-firewall hive $JAVA_ELEMENT"

    # Workaround for https://bugs.launchpad.net/diskimage-builder/+bug/1204824
    # https://bugs.launchpad.net/sahara/+bug/1252684
    if [ "$platform" = 'ubuntu' ]; then
        echo "**************************************************************"
        echo "WARNING: As a workaround for DIB bug 1204824, you are about to"
        echo "         create a Fedora and CentOS images that has SELinux    "
        echo "         disabled. Do not use these images in production.       "
        echo "**************************************************************"
        fedora_elements_sequence="$fedora_elements_sequence selinux-permissive"
        centos_elements_sequence="$centos_elements_sequence selinux-permissive"
        centos7_elements_sequence="$centos7_elements_sequence selinux-permissive"
        suffix=".selinux-permissive"
    fi

    # Ubuntu cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES

        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.6" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_6:-"2.6.0"}
            export ubuntu_image_name=${ubuntu_vanilla_hadoop_2_6_image_name:-"ubuntu_sahara_vanilla_hadoop_2_6_latest"}
            image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export ubuntu_image_name=${ubuntu_vanilla_hadoop_2_7_1_image_name:-"ubuntu_sahara_vanilla_hadoop_2_7_1_latest"}
            image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
        fi
        unset DIB_CLOUD_INIT_DATASOURCES
    fi

    # Fedora cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "fedora" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.6" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_6:-"2.6.0"}
            export fedora_image_name=${fedora_vanilla_hadoop_2_6_image_name:-"fedora_sahara_vanilla_hadoop_2_6_latest$suffix"}
            image_create fedora $fedora_image_name $fedora_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export fedora_image_name=${fedora_vanilla_hadoop_2_7_1_image_name:-"fedora_sahara_vanilla_hadoop_2_7_1_latest$suffix"}
            image_create fedora $fedora_image_name $fedora_elements_sequence
        fi
    fi

    # CentOS 6 cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.6" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_6:-"2.6.0"}
            export centos_image_name=${centos_vanilla_hadoop_2_6_image_name:-"centos_sahara_vanilla_hadoop_2_6_latest$suffix"}
            image_create centos $centos_image_name $centos_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export centos_image_name=${centos_vanilla_hadoop_2_7_1_image_name:-"centos_sahara_vanilla_hadoop_2_7_1_latest$suffix"}
            image_create centos $centos_image_name $centos_elements_sequence
        fi
    fi

    # CentOS 7 cloud image
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.6" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_6:-"2.6.0"}
            export centos7_image_name=${centos7_vanilla_hadoop_2_6_image_name:-"centos7_sahara_vanilla_hadoop_2_6_latest$suffix"}
            image_create centos7 $centos7_image_name $centos7_elements_sequence
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2.7.1" ]; then
            export DIB_HADOOP_VERSION=${DIB_HADOOP_VERSION_2_7_1:-"2.7.1"}
            export centos7_image_name=${centos7_vanilla_hadoop_2_7_1_image_name:-"centos7_sahara_vanilla_hadoop_2_7_1_latest$suffix"}
            image_create centos7 $centos7_image_name $centos7_elements_sequence
        fi
    fi
fi

##########################
# Image for Spark plugin #
##########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "spark" ]; then
    export DIB_HDFS_LIB_DIR="/usr/lib/hadoop"
    export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES
    export DIB_SPARK_VERSION

    COMMON_ELEMENTS="$JAVA_ELEMENT swift_hadoop spark"
    if [ "$DIB_SPARK_VERSION" == "1.0.2" ]; then
        echo "Overriding CDH version, CDH 4 is required for this Spark version"
        export DIB_CDH_VERSION="CDH4"
        ubuntu_elements_sequence="$COMMON_ELEMENTS hadoop-cdh"
    elif [ "$DIB_SPARK_VERSION" == "1.6.0" ]; then
        export DIB_CDH_VERSION="5.4"
        ubuntu_elements_sequence="$COMMON_ELEMENTS hadoop-cloudera"
    else
        export DIB_CDH_VERSION=$HADOOP_VERSION
        ubuntu_elements_sequence="$COMMON_ELEMENTS hadoop-cloudera"
    fi

    # Tell the cloudera element to install only hdfs
    export DIB_CDH_HDFS_ONLY=1

    export ubuntu_image_name=${ubuntu_spark_image_name:-"ubuntu_sahara_spark_latest"}

    # Creating Ubuntu cloud image
    image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
    unset DIB_CLOUD_INIT_DATASOURCES
    unset DIB_HDFS_LIB_DIR
    unset DIB_CDH_HDFS_ONLY
    unset DIB_CDH_VERSION
    unset DIB_SPARK_VERSION
    unset DIB_HADOOP_VERSION
fi


##########################
# Image for Storm plugin #
##########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "storm" ]; then
    export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES

    export DIB_STORM_VERSION=${DIB_STORM_VERSION:-0.9.2}
    export ubuntu_image_name=${ubuntu_storm_image_name:-"ubuntu_sahara_storm_latest_$DIB_STORM_VERSION"}

    ubuntu_elements_sequence="$JAVA_ELEMENT zookeeper storm"

    # Creating Ubuntu cloud image
    image_create ubuntu $ubuntu_image_name $ubuntu_elements_sequence
    unset DIB_CLOUD_INIT_DATASOURCES
fi
#########################
# Images for HDP plugin #
#########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "hdp" ]; then
    echo "For hdp plugin option -i is ignored"

    # Generate HDP images

    # Parameter 'DIB_IMAGE_SIZE' should be specified for CentOS only
    export DIB_IMAGE_SIZE=${IMAGE_SIZE:-"10"}

    # Ignoring image type option
    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "1" ]; then
        export centos_image_name_hdp_1_3=${centos_hdp_hadoop_1_image_name:-"centos-6_6-64-hdp-1-3"}
        # Elements to include in an HDP-based image
        centos_elements_sequence="hadoop-hdp yum $JAVA_ELEMENT"

        # generate image with HDP 1.3
        export DIB_HDP_VERSION="1.3"
        image_create centos $centos_image_name_hdp_1_3 $centos_elements_sequence
    fi

    if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "2" ]; then
        export centos_image_name_hdp_2_0=${centos_hdp_hadoop_2_image_name:-"centos-6_6-64-hdp-2-0"}
        # Elements to include in an HDP-based image
        centos_elements_sequence="hadoop-hdp yum $JAVA_ELEMENT"

        # generate image with HDP 2.0
        export DIB_HDP_VERSION="2.0"
        image_create centos $centos_image_name_hdp_2_0 $centos_elements_sequence
    fi
    unset DIB_IMAGE_SIZE
fi

############################
# Images for Ambari plugin #
############################

if [ -z "$PLUGIN" -o "$PLUGIN" = "ambari" ]; then
    export DIB_AMBARI_VERSION="$HADOOP_VERSION"
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        ambari_ubuntu_image_name=${ambari_ubuntu_image_name:-ubuntu_sahara_ambari}
        ambari_element_sequence="ambari $JAVA_ELEMENT"
        export DIB_RELEASE="precise"
        image_create ubuntu $ambari_ubuntu_image_name $ambari_element_sequence
        unset DIB_RELEASE
    fi
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos" ]; then
        ambari_centos_image_name=${ambari_centos_image_name:-centos_sahara_ambari}
        ambari_element_sequence="ambari $JAVA_ELEMENT disable-firewall"
        image_create centos $ambari_centos_image_name $ambari_element_sequence
    fi
    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        ambari_centos7_image_name=${ambari_centos7_image_name:-"centos7-sahara-ambari"}
        ambari_element_sequence="disable-selinux ambari $JAVA_ELEMENT disable-firewall"
        image_create centos7 $ambari_centos7_image_name $ambari_element_sequence
    fi
    unset DIB_AMBARI_VERSION
fi

#########################
# Images for CDH plugin #
#########################

if [ -z "$PLUGIN" -o "$PLUGIN" = "cloudera" ]; then
    # Cloudera installation requires additional space
    export DIB_MIN_TMPFS=5

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.0" ]; then
            cloudera_5_0_ubuntu_image_name=${cloudera_5_0_ubuntu_image_name:-ubuntu_sahara_cloudera_5_0_0}
            cloudera_elements_sequence="hadoop-cloudera"

            # Cloudera supports only 12.04 Ubuntu
            export DIB_CDH_VERSION="5.0"
            export DIB_RELEASE="precise"
            image_create ubuntu $cloudera_5_0_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.3" ]; then
            cloudera_5_3_ubuntu_image_name=${cloudera_5_3_ubuntu_image_name:-ubuntu_sahara_cloudera_5_3_0}
            cloudera_elements_sequence="hadoop-cloudera"

            # Cloudera supports only 12.04 Ubuntu
            export DIB_CDH_VERSION="5.3"
            export DIB_RELEASE="precise"
            image_create ubuntu $cloudera_5_3_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.4" ]; then
            cloudera_5_4_ubuntu_image_name=${cloudera_5_4_ubuntu_image_name:-ubuntu_sahara_cloudera_5_4_0}
            cloudera_elements_sequence="hadoop-cloudera"

            # Cloudera supports only 12.04 Ubuntu
            export DIB_CDH_VERSION="5.4"
            export DIB_RELEASE="precise"
            image_create ubuntu $cloudera_5_4_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.5" ]; then
            cloudera_5_5_ubuntu_image_name=${cloudera_5_5_ubuntu_image_name:-ubuntu_sahara_cloudera_5_5_0}
            cloudera_elements_sequence="hadoop-cloudera"

            # Cloudera supports 14.04 Ubuntu in 5.5
            export DIB_CDH_VERSION="5.5"
            export DIB_RELEASE="trusty"
            image_create ubuntu $cloudera_5_5_ubuntu_image_name $cloudera_elements_sequence
            unset DIB_CDH_VERSION DIB_RELEASE
        fi
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos" ]; then
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.0" ]; then
            export DIB_CDH_VERSION="5.0"

            cloudera_5_0_centos_image_name=${cloudera_5_0_centos_image_name:-centos_sahara_cloudera_5_0_0}
            cloudera_elements_sequence="hadoop-cloudera selinux-permissive disable-firewall"

            image_create centos $cloudera_5_0_centos_image_name $cloudera_elements_sequence

            unset DIB_CDH_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.3" ]; then
            export DIB_CDH_VERSION="5.3"

            cloudera_5_3_centos_image_name=${cloudera_5_3_centos_image_name:-centos_sahara_cloudera_5_3_0}
            cloudera_elements_sequence="hadoop-cloudera selinux-permissive disable-firewall"

            image_create centos $cloudera_5_3_centos_image_name $cloudera_elements_sequence

            unset DIB_CDH_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.4" ]; then
            export DIB_CDH_VERSION="5.4"

            cloudera_5_4_centos_image_name=${cloudera_5_4_centos_image_name:-centos_sahara_cloudera_5_4_0}
            cloudera_elements_sequence="hadoop-cloudera selinux-permissive disable-firewall"

            image_create centos $cloudera_5_4_centos_image_name $cloudera_elements_sequence

            unset DIB_CDH_VERSION
        fi
        if [ -z "$HADOOP_VERSION" -o "$HADOOP_VERSION" = "5.5" ]; then
            export DIB_CDH_VERSION="5.5"

            cloudera_5_5_centos_image_name=${cloudera_5_5_centos_image_name:-centos_sahara_cloudera_5_5_0}
            cloudera_elements_sequence="hadoop-cloudera selinux-permissive disable-firewall"

            image_create centos $cloudera_5_5_centos_image_name $cloudera_elements_sequence

            unset DIB_CDH_VERSION
        fi
    fi
    unset DIB_MIN_TMPFS
fi

##########################
# Images for MapR plugin #
##########################
if [ -z "$PLUGIN" -o "$PLUGIN" = "mapr" ]; then
    export DIB_MAPR_VERSION=${DIB_MAPR_VERSION:-${DIB_DEFAULT_MAPR_VERSION}}

    export DIB_CLOUD_INIT_DATASOURCES=$CLOUD_INIT_DATASOURCES

    export DIB_IMAGE_SIZE=${IMAGE_SIZE:-"10"}
    #MapR repository requires additional space
    export DIB_MIN_TMPFS=10

    mapr_ubuntu_elements_sequence="ssh hadoop-mapr $JAVA_ELEMENT"
    mapr_centos_elements_sequence="ssh hadoop-mapr selinux-permissive $JAVA_ELEMENT disable-firewall"

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        export DIB_RELEASE=${DIB_RELEASE:-trusty}

        mapr_ubuntu_image_name=${mapr_ubuntu_image_name:-ubuntu_${DIB_RELEASE}_mapr_${DIB_MAPR_VERSION}_latest}

        image_create ubuntu $mapr_ubuntu_image_name $mapr_ubuntu_elements_sequence

        unset DIB_RELEASE
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos" ]; then
        mapr_centos_image_name=${mapr_centos_image_name:-centos_6.6_mapr_${DIB_MAPR_VERSION}_latest}

        image_create centos $mapr_centos_image_name $mapr_centos_elements_sequence

        unset DIB_CLOUD_INIT_DATASOURCES
    fi
fi

################
# Plain images #
################
if [ -z "$PLUGIN" -o "$PLUGIN" = "plain" ]; then
    # generate plain (no Hadoop components) images for testing

    common_elements="ssh"

    ubuntu_elements_sequence="$common_elements"
    fedora_elements_sequence="$common_elements"
    centos_elements_sequence="$common_elements disable-firewall disable-selinux"
    centos7_elements_sequence="$common_elements disable-firewall disable-selinux"

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "ubuntu" ]; then
        plain_image_name=${plain_ubuntu_image_name:-ubuntu_plain}

        image_create ubuntu $plain_image_name $ubuntu_elements_sequence
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "fedora" ]; then
        plain_image_name=${plain_fedora_image_name:-fedora_plain}

        image_create fedora $plain_image_name $fedora_elements_sequence
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos" ]; then
        plain_image_name=${plain_centos_image_name:-centos_plain}

        image_create centos $plain_image_name $centos_elements_sequence
    fi

    if [ -z "$BASE_IMAGE_OS" -o "$BASE_IMAGE_OS" = "centos7" ]; then
        plain_image_name=${plain_centos7_image_name:-centos7_plain}

        image_create centos7 $plain_image_name $centos7_elements_sequence
    fi
fi
