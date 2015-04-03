=====
spark
=====

Installs Spark on Ubuntu. Requires Hadoop CDH 4 (hadoop-cdh element).

It will install a version of Spark known to be compatible with CDH 4
This behaviour can be controlled also by using 'DIB_SPARK_VERSION' or directly with
'SPARK_DOWNLOAD_URL'

If you set 'SPARK_CUSTOM_DISTRO' to 1, you can point the 'SPARK_DOWNLOAD_URL'
variable to a custom Spark distribution created with the make-distribution.sh
script included in Spark.
