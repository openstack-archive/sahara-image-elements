=====
extjs
=====

This element downloads extjs from its website, caching it so it is
not downloaded every time, and optionally unpacking it.

Configuration
-------------

The element can be configured by exporting variables using a
`environment.d` script; variables with ``*`` are mandatory:

* EXTJS\_DESTINATION\_DIR ``*``

  The directory where to extract (or copy) extjs.  Mandatory, must be
  an absolute directory within the image, e.g. ``/usr/share/someapp``.
  The directory is created if not existing already.

* EXTJS\_DOWNLOAD\_URL

  The URL from where to download extjs.  Defaults to
  ``http://extjs.com/deploy/ext-2.2.zip``.

* EXTJS\_NO\_UNPACK

  If set to 1, then the extjs tarball is simply copied to the location
  specified by EXTJS\_DESTINATION\_DIR.
