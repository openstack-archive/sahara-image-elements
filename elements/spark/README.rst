=====
spark
=====

Installs Spark. Requires Hadoop.

This element will install Spark. It tries to guess the
correct file to download based on the ``DIB_SPARK_VERSION`` and
``DIB_CDH_VERSION``, but this behaviour can be overridden by using
``SPARK_DOWNLOAD_URL`` to specify a download URL for a pre-built
Spark tar.gz file.
See http://spark.apache.org/downloads.html for more download options.

Versions
--------

This element is able to generate images containing any valid Spark version,
compiled against one version of Hadoop HDFS libraries.

Only some combinations of Spark and Hadoop versions are possible, depending on
the availability of a pre-compiled binary and only few of them are tested with
the Sahara Spark plugin.

The ``diskimage-create.sh`` script will use tested defaults. Those defaults
generate an image supported by the Sahara Spark plugin. Other combinations
should be used only for evaluation or testing purposes. Refer to the Sahara
Spark plugin wiki page (https://wiki.openstack.org/wiki/Sahara/SparkPlugin)
for more information about tested and supported versions.

Environment Variables
---------------------

DIB_SPARK_VERSION
  :Required: Yes, if ``SPARK_DOWNLOAD_URL`` is not set.
  :Description: Version of the Spark package to download.
  :Example: ``DIB_SPARK_VERSION=1.3.1``

DIB_CDH_VERSION
  :Required: Required only for images for Spark Plugin and
    if ``SPARK_DOWNLOAD_URL`` is not set.
  :Description: Version of the CDH platform to use for Hadoop compatibility.
    CDH version 5.3 is known to work well.
  :Example: ``DIB_CDH_VERSION=5.3``

SPARK_DOWNLOAD_URL
  :Required: No, if set overrides ``DIB_CDH_VERSION`` and ``DIB_SPARK_VERSION``
  :Description: Download URL of a tgz Spark package to override the automatic
    selection from the Apache repositories.
