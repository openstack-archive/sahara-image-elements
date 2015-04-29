====
hive
====

Installs Hive on Ubuntu and Fedora.

Hive stores metadata in MySQL databases. So, this element requires the
``mysql`` element.

Environment Variables
---------------------

HIVE_VERSION
  :Required: Yes, if ``HIVE_DOWNLOAD_URL`` is not set.
  :Description: Version of Hive to fetch from apache.org.
  :Example: ``HIVE_VERSION=0.11.0``

HIVE_DOWNLOAD_URL
  :Required: Yes, if ``HIVE_VERSION`` is not set.
  :Default: ``http://archive.apache.org/dist/hive/hive-$HIVE_VERSION/hive-$HIVE_VERSION-bin.tar.gz``
  :Description: Download URL of the Hive package.
