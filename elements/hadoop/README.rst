======
hadoop
======

Installs Java and Hadoop, configures SSH.

HOWTO build Hadoop Native Libs
------------------------------

- Install: *jdk >= 6*, *maven*, *cmake* and *protobuf >= 2.5.0*

- Get Hadoop source code:

  .. code:: bash

     wget http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0-src.tar.gz

- Unpack source:

  .. code:: bash

     tar xvf hadoop-2.6.0-src.tar.gz

- Build Hadoop:

  .. code:: bash

     cd hadoop-2.6.0-src
     mvn package -Pdist,native -DskipTests

- Create tarball with Hadoop Native Libs:

  .. code:: bash

     cd hadoop-dist/target/hadoop-2.6.0/lib
     tar -czvf hadoop-native-libs-2.6.0.tar.gz native
