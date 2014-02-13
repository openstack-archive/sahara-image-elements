==Install Java==

This element installs a Java Virtual Machine into the image. There are
three options for selecting what version of the JVM is installed -

0. Provide no input, the package manager in your image will be used to
install the natively packaged JVM

1. Provide JAVA_FILE via the environment, it should be a .tar.gz or
.bin and will be install under /usr/java

2. Provide JAVA_DOWNLOAD_URL via the environment, it should be a url
pointing to a file that will be placed in JAVA_FILE (see 1.)
