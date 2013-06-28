Diskimage-builder tools for creation cloud images
=================================================

Steps how to create cloud image with Apache Hadoop installed using diskimage-builder project:

1. Clone the repository "https://github.com/stackforge/diskimage-builder" locally.

.. sourcecode:: bash

    git clone https://github.com/stackforge/diskimage-builder

2. Add ~/diskimage-builder/bin/ directory to your path (for example, PATH=$PATH:/home/$USER/diskimage-builder/bin/ ).

3. Export the following variable ELEMENTS_PATH=/home/$USER/diskimage-builder/elements/ to your .bashrc. Then source it.

4. Copy file "img-build-sudoers" from ~/disk-image-builder/sudoers.d/ to your /etc/sudoers.d/

.. sourcecode:: bash

    chmod 440 /etc/sudoers.d/img-build-sudoers
    chown root:root /etc/sudoers.d/img-build-sudoers

5. Move elements/ directory to disk-image-builder/elements/

.. sourcecode:: bash

    mv elements/*  /path_to_disk_image_builder/diskimage-builder/elements/

6. Call the following command to create cloud image is able to run on OpenStack:

6.1. Ubuntu cloud image

.. sourcecode:: bash

    JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.1.2 disk-image-create base vm hadoop ubuntu root-passwd -o hadoop_1_1_2

6.2. Fedora cloud image

.. sourcecode:: bash

    DIB_HADOOP_VERSION=1.1.2 JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_IMAGE_SIZE=10 disk-image-create base vm fedora hadoop_fedora root-passwd -o fedora_hadoop_1_1_2

In this command 'DIB_HADOOP_VERSION' parameter is version of hadoop needs to be installed.
You can use 'JAVA_DOWNLOAD_URL' parameter to specify download link for JDK (tarball or bin).
'DIB_IMAGE_SIZE' is parameter that specifes a volume of hard disk of instance. You need to specify it because Fedora doesn't use all available volume.
In case if you have already downloaded jdk package, move it to "elements/hadoop/install.d/" and use its filename as 'JAVA_FILE' parameter.
