============
swift_hadoop
============

Install the Hadoop swift connector jar file into the image. By default, this
jar file is generated from the sources available in the sahara-extras
repository.

Environment Variables
---------------------

swift_url
  :Required: No
  :Default: https://tarballs.openstack.org/sahara-extra/dist/hadoop-openstack/master/hadoop-openstack-2.7.1.jar
  :Description: Location of the swift jar file.

DIB_HDFS_LIB_DIR
  :Required: No
  :Default: /usr/share/hadoop/lib
  :Description: Directory in the guest where to save the swift jar.

DIB_HADOOP_SWIFT_JAR_NAME
  :Required: No
  :Default: hadoop-openstack.jar
  :Description: Filename of the deployed swift jar.
