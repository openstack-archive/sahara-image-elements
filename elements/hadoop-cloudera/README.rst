===============
hadoop-cloudera
===============

Installs cloudera (cloudera-manager-agent cloudera-manager-daemons
cloudera-manager-server cloudera-manager-server-db-2 hadoop-hdfs-namenode
hadoop-hdfs-secondarynamenode hadoop-hdfs-datanode hadoop-yarn-resourcemanager
hadoop-yarn-nodemanager hadoop-mapreduce hadoop-mapreduce-historyserver) and
Java (oracle-j2sdk1.7) packages from cloudera repositories:
`cdh5 <http://archive.cloudera.com/cdh5/>`_ and
`cm5 <http://archive.cloudera.com/cm5>`_.

Also installs Cloudera distribution of Apache Kafka for CDH version >= 5.5 from
Cloudera repository: `kafka <http://archive.cloudera.com/kafka>`_.

In order to create the Cloudera images with ``diskimage-create.sh``, use the
following syntax to select the ``cloudera`` plugin:

.. sourcecode:: bash

  diskimage-create.sh -p cloudera

Environment Variables
---------------------

The element can be configured by exporting variables using a
`environment.d` script.

DIB_CDH_HDFS_ONLY
  :Required: No
  :Description: If set will install only the namenode and datanode
    packages with their dependencies.

DIB_CDH_MINOR_VERSION
  :Required: No
  :Description: If set will install minor version of CDH. Available minor
    versions are 5.7.x.
