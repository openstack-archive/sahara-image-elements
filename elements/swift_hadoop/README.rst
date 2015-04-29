============
swift_hadoop
============

Install a Swift jar file into the image.

Environment Variables
---------------------

swift_url
  :Required: No
  :Default: http://sahara-files.mirantis.com/hadoop-swift/hadoop-swift-latest.jar
  :Description: Location of the Swift jar file.

HDFS_LIB_DIR
  :Required: No
  :Default: /usr/lib/hadoop
  :Description: Directory in the guest where to save the Swift jar.
