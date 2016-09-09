================
hdp-local-mirror
================

This element creates mirror with HDP packages.

Environment Variables
---------------------

DIB_HDP_STACK_URL
  :Required: Yes
  :Description: URL of the HDP stack
  :Example: ``DIB_HDP_STACK_URL="http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.2.0/HDP-2.3.2.0-centos6-rpm.tar.gz"``

DIB_HDP_UTILS_URL
  :Required: Yes
  :Description: URL of HDP Utils
  :Example: ``DIB_HDP_UTILS_URL="http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.20/repos/centos6/HDP-UTILS-1.1.0.20-centos6.tar.gz"``
