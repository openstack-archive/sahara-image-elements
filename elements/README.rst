Diskimage-builder tools for creation cloud images
=================================================

Steps how to create cloud image with Apache Hadoop installed using diskimage-builder project:

1. Clone the repository "https://github.com/openstack/diskimage-builder" locally. Note: Make sure you have commit 43b96d91 in your clone, it provides a mapping for default-jre.

.. sourcecode:: bash

    git clone https://github.com/openstack/diskimage-builder

2. Add ~/diskimage-builder/bin/ directory to your path (for example, PATH=$PATH:/home/$USER/diskimage-builder/bin/ ).

3. Export the following variable ELEMENTS_PATH=/home/$USER/diskimage-builder/elements/ to your .bashrc. Then source it.

4. Copy file "img-build-sudoers" from ~/disk-image-builder/sudoers.d/ to your /etc/sudoers.d/.

.. sourcecode:: bash

    chmod 440 /etc/sudoers.d/img-build-sudoers
    chown root:root /etc/sudoers.d/img-build-sudoers

5. Export sahara-elements commit id variable (from sahara-extra directory):

.. sourcecode:: bash

    export SAHARA_ELEMENTS_COMMIT_ID=`git show --format=%H | head -1`

6. Move elements/ directory to disk-image-builder/elements/

.. sourcecode:: bash

    mv elements/*  /path_to_disk_image_builder/diskimage-builder/elements/

7. Export DIB commit id variable (from DIB directory):

.. sourcecode:: bash

    export DIB_COMMIT_ID=`git show --format=%H | head -1`

8. Call the following command to create cloud image is able to run on OpenStack:

8.1. Ubuntu cloud image

.. sourcecode:: bash

    JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.2.1 OOZIE_FILE=oozie-4.0.0.tar.gz disk-image-create base vm hadoop oozie ubuntu root-passwd -o ubuntu_hadoop_1_2_1

8.2. Fedora cloud image

.. sourcecode:: bash

    JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.2.1 OOZIE_FILE=oozie-4.0.0.tar.gz DIB_IMAGE_SIZE=10 disk-image-create base vm fedora hadoop root-passwd oozie -o fedora_hadoop_1_2_1

Note: If you are building this image from Ubuntu or Fedora 18 OS host, you should add element 'selinux-permissive'.

.. sourcecode:: bash

    JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.2.1 OOZIE_FILE=oozie-4.0.0.tar.gz DIB_IMAGE_SIZE=10 disk-image-create base vm fedora hadoop root-passwd oozie selinux-permissive -o fedora_hadoop_1_2_1

In this command 'DIB_HADOOP_VERSION' parameter is version of hadoop needs to be installed.
You can use 'JAVA_DOWNLOAD_URL' parameter to specify download link for JDK (tarball or bin).
'DIB_IMAGE_SIZE' is parameter that specifes a volume of hard disk of instance. You need to specify it because Fedora and CentOS don't use all available volume.
If you have already downloaded the jdk package, move it to "elements/hadoop/install.d/" and use its filename as 'JAVA_FILE' parameter.
In order of working EDP components with Sahara DIB images you need pre-installed Oozie libs.
Use OOZIE_DOWNLOAD_URL to specify link to Oozie archive (tar.gz). For example the Oozie libraries
for Hadoop 2.7.1 are available from:
https://tarballs.openstack.org/sahara-extra/dist/oozie/oozie-4.2.0-hadoop-2.7.1.tar.gz
If you have already downloaded archive, move it to "elements/oozie/install.d/" and use its filename as 'OOZIE_FILE' parameter.
