Diskimage-builder script for creation cloud images
=================================================

This scrtips builds Ubuntu and Fedora cloud images with default parameters.

For users:

1. Use your environment (export / setenv) to alter the scripts behavior. Environment variables the script accepts are DIB_HADOOP_VERSION, JAVA_DOWNLOAD_URL, OOZIE_DOWNLOAD_URL, HIVE_VERSION, ubuntu_image_name, fedora_image_name.

2. If you want to use your local mirrors, you should specify http urls for Fedora and Ubuntu mirrors using parameters 'FEDORA_MIRROR' and 'UBUNTU_MIRROR' like this:

.. sourcecode:: bash

  sudo USE_MIRRORS=true FEDORA_MIRROR="url_for_fedora_mirror" UBUNTU_MIRROR="url_for_ubuntu_mirror" bash diskimage-create.sh

For developers:

1. If you want to add your element to this repository, you should edit this script in your commit (you should export variables for your element and add name of element to variables 'element_sequence').
