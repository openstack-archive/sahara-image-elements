=========
s3_hadoop
=========

Copy the Hadoop S3 connector jar file into the Hadoop classpath.

Environment Variables
---------------------

HADOOP_S3_JAR_ORIGIN
  :Required: No
  :Default: Depends on plugin.
  :Description: Path to where the S3 jar is (already) located.

HADOOP_S3_JAR_DOWNLOAD
  :Required: No
  :Default: None.
  :Description: If set, use a download a specific S3 jar instead of one already available on the image.

DIB_HDFS_LIB_DIR
  :Required: No
  :Default: /usr/share/hadoop/lib
  :Description: Directory in the guest where to save the S3 jar. Shared with swift_hadoop.
