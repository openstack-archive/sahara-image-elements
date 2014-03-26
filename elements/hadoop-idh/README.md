Install the Intel Distribution Hadoop

The following script:

sahara-image-elements/diskimage-create/diskimage-create.sh

is the default script to use for creating CentOS images with IDH installed/configured.

The available versions of Intel Hadoop are 2.5.1 and 3.0.2 now. If you want build 2.5.1 version then you should specify -v as 1. If you want build 3.0.2 version then you should specify -v as 2.

In order to create the IDH images with the diskimage-create.sh script, use the following syntax to select the "idh" plugin:

diskimage-create.sh -p idh -v 1|2
