==========
hadoop-cdh
==========

Installs Hadoop CDH 4 (the Cloudera distribution), configures SSH.
Only HDFS is installed at this time.

This element is used by Spark version 1.0.2.

This element is deprecated and will be deleted when support for Spark 1.0.2
will be dropped from Sahara.


Environment Variables
---------------------

DIB_CDH_VERSION
  :Required: Yes.
  :Description: Version of the CDH platform to install.
  :Example: ``DIB_CDH_VERSION=CDH4``

