===========
hadoop-mapr
===========

Creates images with local mirrors of MapR repositories:
`core <http://package.mapr.com/releases/>`_ and
`ecosystem <http://package.mapr.com/releases/ecosystem-4.x/>`_.
Installs `OpenJDK <http://http://openjdk.java.net/>`_ and
`Scala <https://www.scala-lang.org/>`_.

In order to create the MapR images with ``diskimage-create.sh``, use the
following syntax to select the ``MapR`` plugin:

.. sourcecode:: bash

  diskimage-create.sh -p mapr [-i ubuntu|centos7|rhel7] [-r 5.1.0 | 5.2.0]

In order to speed up image creation process you can download archives with MapR
repositories and specify environment variables:
``DIB_MAPR_CORE_DEB_REPO``, ``DIB_MAPR_CORE_RPM_REPO``,
``DIB_MAPR_ECO_DEB_REPO``, ``DIB_MAPR_ECO_RPM_REPO``.

For example:

.. sourcecode:: bash

  export DIB_MAPR_CORE_DEB_REPO="file://<path-to-archive>/mapr-v5.2.0GA.deb.tgz"
  export DIB_MAPR_CORE_RPM_REPO="file://<path-to-archive>/mapr-v5.2.0GA.rpm.tgz"
  export DIB_MAPR_ECO_DEB_REPO="http://<URL>/mapr-ecosystem.deb.tgz"
  export DIB_MAPR_ECO_RPM_REPO="http://<URL>/mapr-ecosystem.rpm.tgz"
  diskimage-create.sh -p mapr -r 5.2.0

Environment Variables
---------------------

DIB_MAPR_VERSION
  :Required: Yes
  :Description: Version of MapR to install.
  :Example: ``DIB_MAPR_VERSION=5.2.0``

SCALA_VERSION
  :Required: No
  :Description: Force a specific version of Scala (disable autodetection).
  :Example: ``SCALA_VERSION=2.12.2``
