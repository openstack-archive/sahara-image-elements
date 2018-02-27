=====
extjs
=====

This element downloads extjs from its website, caching it so it is
not downloaded every time, and optionally unpacking it.

Environment Variables
---------------------

The element can be configured by exporting variables using a
`environment.d` script.

EXTJS_DESTINATION_DIR
  :Required: Yes
  :Description: The directory where to extract (or copy) extjs; must be
    an absolute directory within the image. The directory is created if not
    existing already.
  :Example: ``EXTJS_DESTINATION_DIR=/usr/share/someapp``

EXTJS_DOWNLOAD_URL
  :Required: No
  :Default: ``https://tarballs.openstack.org/sahara-extra/dist/common-artifacts/ext-2.2.zip``
  :Description: The URL from where to download extjs.

EXTJS_NO_UNPACK
  :Required: No
  :Default: *unset*
  :Description: If set to 1, then the extjs tarball is simply copied to the
    location specified by ``EXTJS_DESTINATION_DIR``.
