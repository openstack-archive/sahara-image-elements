Hadoop patch for Swift Integration
=================================

Hadoop and Swift integration is the essential continuation of Hadoop&OpenStack marriage. There were two steps to achieve this:

* Hadoop side: a FileSystem implementation for Swift: https://issues.apache.org/jira/browse/HADOOP-8545 .

* Swift side: https://review.openstack.org/#/c/21015/. This patch is merged into Grizzly. But if you want to make it work in Folsom please see the instructions in https://savanna.readthedocs.org/ .

Hadoop patching
---------------
You need to put /hadoop-patch/hadoop-swift-latest.jar file to hadoop libraries (e.g. /usr/lib/share/hadoop/lib) into each job-tracker and task-tracker node in cluster.
How to configure core-site.xml please see at https://savanna.readthedocs.org/ .