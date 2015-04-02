===========
oracle-java
===========

This element installs a Java Virtual Machine into the image. There are
three options for selecting what version of the JVM is installed -

0. Provide no input, the package manager in your image will be used to
install the natively packaged JVM

1. Provide JAVA_FILE via the environment, it should be a .tar.gz or
.bin and will be installed under JAVA_TARGET_LOCATION, which will default
to "/usr/java" (see 3. for more information on JAVA_TARGET_LOCATION).

2. Provide JAVA_DOWNLOAD_URL via the environment, it should be a url
pointing to a file that will be placed in JAVA_FILE (see 1.)

3. In addition to selecting the JDK to install, this element can be
configured to install to a specific location.  Set the JAVA_TARGET_LOCATION
variable in order to customize the top-level directory that will
contain the JDK install.  By default, this variable is set to "/usr/java".
