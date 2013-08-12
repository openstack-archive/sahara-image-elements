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

5. Export savanna-elements commit id variable (from savanna-extra directory):

.. sourcecode:: bash

    export SAVANNA_ELEMENTS_COMMIT_ID=`git show --format=%H | head -1`

6. Move elements/ directory to disk-image-builder/elements/

.. sourcecode:: bash

    mv elements/*  /path_to_disk_image_builder/diskimage-builder/elements/

7. Export DIB commit id variable (from DIB directory):

.. sourcecode:: bash

    export DIB_COMMIT_ID=`git show --format=%H | head -1`

8. Call the following command to create cloud image is able to run on OpenStack:

8.1. Ubuntu cloud image

.. sourcecode:: bash

    JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.1.2 OOZIE_FILE=oozie-3.3.2.tar.gz disk-image-create base vm hadoop oozie ubuntu root-passwd -o hadoop_1_1_2

8.2. Fedora cloud image

.. sourcecode:: bash

    JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.1.2 DIB_IMAGE_SIZE=10 disk-image-create base vm fedora hadoop root-passwd -o fedora_hadoop_1_1_2

Note: If you build Fedora 19 image from a non-Fedora 19 host (e.g. Ubuntu or Fedora 18), you should use the parameter 'WORKAROUND_BUG_1204824'. If this bug doesn't have status 'fix-commited', give to parameter 'WORKAROUND_BUG_1204824' not empty value.
Bug: https://bugs.launchpad.net/diskimage-builder/+bug/1204824

.. sourcecode:: bash

    WORKAROUND_BUG_1204824=true JAVA_FILE=jdk-7u21-linux-x64.tar.gz DIB_HADOOP_VERSION=1.1.2 DIB_IMAGE_SIZE=10 disk-image-create base vm fedora hadoop root-passwd -o fedora_hadoop_1_1_2

In this command 'DIB_HADOOP_VERSION' parameter is version of hadoop needs to be installed.
You can use 'JAVA_DOWNLOAD_URL' parameter to specify download link for JDK (tarball or bin).
'DIB_IMAGE_SIZE' is parameter that specifes a volume of hard disk of instance. You need to specify it because Fedora doesn't use all available volume.
If you have already downloaded the jdk package, move it to "elements/hadoop/install.d/" and use its filename as 'JAVA_FILE' parameter.
In order of working EDP components with Savanna DIB images you need pre-installed Oozie libs.
Use OOZIE_DOWNLOAD_URL to specify link to Oozie archive (tar.gz). For example we have built Oozie libs here:
http://a8e0dce84b3f00ed7910-a5806ff0396addabb148d230fde09b7b.r31.cf1.rackcdn.com/oozie-3.3.2.tar.gz
If you have already downloaded archive, move it to "elements/oozie/install.d/" and use its filename as 'OOZIE_FILE' parameter.
