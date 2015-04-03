==========
hadoop-hdp
==========

Installs the JDK, the Hortonworks Data Platform, and Apache Ambari.

Please set the DIB_HDP_VERSION environment variable to configure the install to use a given version.  The default script (mentioned below) sets this variable for each supported version.

Currently, the following versions of the Hortonworks Data Platform are supported for image building:

1.3
2.0

The following script:

sahara-image-elements/diskimage-create/diskimage-create.sh

is the default script to use for creating CentOS images with HDP installed/configured.  This script can be used without modification, or can be used as an example to describe how a more customized script may be created with the "hadoop-hdp" diskimage-builder element.

In order to create the HDP images with the diskimage-create.sh script, use the following syntax to select the "hdp" plugin:

    diskimage-create.sh -p hdp
