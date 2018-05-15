Diskimage-builder script for creation cloud images
==================================================

This script builds Ubuntu, Fedora, CentOS cloud images for use in Sahara.
By default the all plugin are targeted, all images will be built. The '-p'
option can be used to select plugin (vanilla, spark, cloudera, storm, mapr,
ambari, or plain). The '-i' option can be used to select image type (ubuntu,
fedora, or centos7). The '-v' option can be used to select hadoop
version.

For users:

1. Use your environment (export / setenv) to alter the scripts behavior.
Environment variables the script accepts are 'DIB_HADOOP_VERSION_2_7_1',
'JAVA_DOWNLOAD_URL', 'JAVA_TARGET_LOCATION', 'OOZIE_DOWNLOAD_URL',
'HIVE_VERSION',
'[ubuntu|fedora|centos7]_vanilla_hadoop_2_7_1_image_name',
'ubuntu_spark_image_name', 'ubuntu_storm_image_name',
'ambari_[ubuntu|centos7]_image_name',
'cloudera_[5_7|5_9|5_11]_[ubuntu|centos7]_image_name',
'mapr_[ubuntu|centos7]_image_name',
'plain_[ubuntu|fedora|centos7]_image_name'.

2. For creating all images just clone this repository and run script.

.. sourcecode:: bash

  tox -e venv -- sahara-image-create

3. If you want to use your local mirrors, you should specify http urls for
Fedora, CentOS and Ubuntu mirrors using parameters 'FEDORA_MIRROR',
'CENTOS_MIRROR' and 'UBUNTU_MIRROR' like this:

.. sourcecode:: bash

  USE_MIRRORS=true FEDORA_MIRROR="url_for_fedora_mirror" \
  CENTOS_MIRROR="url_for_centos_mirror" \
  UBUNTU_MIRROR="url_for_ubuntu_mirror" tox -e venv -- sahara-image-create

If you want to use your local image, you can specify path of image file using
parameters 'DIB_LOCAL_IMAGE', which defined in project `[diskimage-builder]
(https://github.com/openstack/diskimage-builder)`, like this:

.. sourcecode:: bash

  DIB_LOCAL_IMAGE="path_of_image" tox -e venv -- sahara-image-create

NOTE: Do not create all images for all plugins with the same mirrors.
Different plugins use different OS version.

4. To select which plugin to target use the '-p' commandline option like this:

.. sourcecode:: bash

  tox -e venv -- sahara-image-create -p [vanilla|spark|cloudera|storm|mapr|ambari|plain]

5. To select which hadoop version to target use the '-v' commandline option
like this:

.. sourcecode:: bash

  tox -e venv -- sahara-image-create -v [2.7.1|5.5|5.7|5.9]

Also, if you are planning to select which ambari version to target use the
'-v' commandline option like this:

.. sourcecode:: bash

  tox -e venv -- sahara-image-create -v [2.2.0.0|2.2.1.0|2.4.2.0]

6. To select which operating system to target use the '-i' commandline option
like this:

.. sourcecode:: bash

  tox -e venv -- sahara-image-create -i [ubuntu|fedora|centos7]

7. To select which Spark version to target use the '-s' commandline option
like this:

.. sourcecode:: bash

  tox -e venv -- sahara-image-create -p spark -s [1.3.1|1.6.0|2.1.0|2.2.0] # spark standalone
  tox -e venv -- sahara-image-create -p vanilla -v 2.7.1 -s [1.6.0|2.1.0|2.2.0] # spark on vanilla

8. To select which MapR version to target use the '-r' commandline option like
this:

.. sourcecode:: bash

  tox -e venv -- sahara-image-create -p mapr -r [5.1.0|5.2.0]

9. If the host system is missing packages required for sahara-image-create,
the '-u' commandline option will instruct the script to install them without
prompt.

NOTE for 4, 5, 6:

For Vanilla you can create ubuntu, fedora and centos7 cloud image with 2.x.x
versions. Use environment variables 'DIB_HADOOP_VERSION_2' to change defaults.
For Spark you can create only ubuntu images, so you shouldn't specify an image
type. The default Spark and HDFS versions included in the build are tested and
known working together with the Sahara Spark plugin, other combinations should
be used only for evaluation or testing purposes. You can select a different
Spark version with commandline option '-s' and Hadoop HDFS version with '-v',
but only Cludera CDH versions are available for now. For Cloudera you can
create ubuntu and centos7 images with preinstalled cloudera hadoop. You
shouldn't specify hadoop version. You can create centos7, ubuntu, fedora images
without hadoop ('plain' image)

NOTE for CentOS images (for vanilla, ambari, and cloudera plugins):

Resizing disk space during firstboot on that images fails with errors
(https://storyboard.openstack.org/#!/story/1304100). So, you will get an instance
that will have a small available disk space. To solve this problem we build
images with 10G available disk space as default. If you need in more available
disk space you should export parameter DIB_IMAGE_SIZE:

.. sourcecode:: bash

  DIB_IMAGE_SIZE=40 tox -e venv -- sahara-image-create -i centos7

For all other images parameter DIB_IMAGE_SIZE will be unset.

`DIB_CLOUD_INIT_DATASOURCES` contains a growing collection of data source
modules and most are enabled by default.  This causes cloud-init to query each
data source on first boot.  This can cause delays or even boot problems
depending on your environment. You must define `DIB_CLOUD_INIT_DATASOURCES` as
a comma-separated list of valid data sources to limit the data sources that
will be queried for metadata on first boot.


For developers:

If you want to add your element to this repository, you should edit this
script in your commit (you should export variables for your element and add
name of element to variables 'element_sequence').
