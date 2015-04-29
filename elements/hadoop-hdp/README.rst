==========
hadoop-hdp
==========

Installs the JDK, the Hortonworks Data Platform, and Apache Ambari.

Currently, the following versions of the Hortonworks Data Platform are
supported for image building:

 - 1.3
 - 2.0

The following script:

.. code:: bash

  diskimage-create/diskimage-create.sh

is the default script to use for creating CentOS images with HDP
installed/configured.  This script can be used without modification, or can
be used as an example to describe how a more customized script may be created
with the ``hadoop-hdp`` element.

In order to create the HDP images with ``diskimage-create.sh``, use the
following syntax to select the ``hdp`` plugin:

.. code:: bash

    diskimage-create.sh -p hdp

Environment Variables
---------------------

DIB_HDP_VERSION
  :Required: Yes
  :Description: Version of the Hortonworks Data Platform to install.
  :Example: ``DIB_HDP_VERSION=2.0``
