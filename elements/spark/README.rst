=====
spark
=====

Installs Spark on Ubuntu. Requires Hadoop CDH 4 (``hadoop-cdh`` element).

It will install a version of Spark known to be compatible with CDH 4;
this behaviour can be controlled also by using ``DIB_SPARK_VERSION`` or
directly with ``SPARK_DOWNLOAD_URL``.

Environment Variables
---------------------

DIB_HADOOP_VERSION
  :Required: Yes, if ``SPARK_DOWNLOAD_URL`` is not set.
  :Description: Version of the Hadoop platform. See also
    http://spark.apache.org/docs/latest/hadoop-third-party-distributions.html.
  :Example: ``DIB_HADOOP_VERSION=CDH4``

DIB_SPARK_VERSION
  :Required: No
  :Default: Depends on ``DIB_HADOOP_VERSION``.
  :Description: Version of Spark to download from apache.org.

SPARK_DOWNLOAD_URL
  :Required: Yes, if ``DIB_HADOOP_VERSION`` is not set.
  :Default: ``http://archive.apache.org/dist/spark/spark-$DIB_SPARK_VERSION/spark-$DIB_SPARK_VERSION-bin-$SPARK_HADOOP_DL.tgz``
  :Description: Download URL of the Spark package.
