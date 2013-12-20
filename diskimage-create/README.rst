Diskimage-builder script for creation cloud images
==================================================

This scrtips builds Ubuntu, Fedora, CentOS cloud images with default parameters.

NOTE: You should use Ubuntu or Fedora host OS for building images, CentOS as a host OS has not been tested well.

For users:

1. Use your environment (export / setenv) to alter the scripts behavior. Environment variables the script accepts are 'DIB_HADOOP_VERSION', 'JAVA_DOWNLOAD_URL', 'OOZIE_DOWNLOAD_URL', 'HIVE_VERSION', 'ubuntu_image_name', 'fedora_image_name'.

2. For creating images just clone this repository and run script.

.. sourcecode:: bash

  sudo bash savanna-image-elements/diskimage-create/diskimage-create.sh

3. If you want to use your local mirrors, you should specify http urls for Fedora and Ubuntu mirrors using parameters 'FEDORA_MIRROR' and 'UBUNTU_MIRROR' like this:

.. sourcecode:: bash

  sudo USE_MIRRORS=true FEDORA_MIRROR="url_for_fedora_mirror" UBUNTU_MIRROR="url_for_ubuntu_mirror" bash savanna-image-elements/diskimage-create/diskimage-create.sh

For developers:

1. If you want to add your element to this repository, you should edit this script in your commit (you should export variables for your element and add name of element to variables 'element_sequence').

2. If you want to test your Patch Set to savanna-image-elements or diskimage-builder, you can specify 'SIM_REPO_PATH' or 'DIB_REPO_PATH' (this parameters should be a full path to repositories) and run this script like this:

.. sourcecode:: bash

  sudo SIM_REPO_PATH="$(pwd)/savanna-image-elements" DIB_REPO_PATH="$(pwd)/diskimage-builder" bash savanna-image-elements/diskimage-create/diskimage-create.sh
