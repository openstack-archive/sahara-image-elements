We have CentOS 6.4 and 6.5 cloud images. Recommended is CentOS 6.5 (http://sahara-files.mirantis.com/CentOS-6.5-cloud-init.qcow2).

For preparing your own CentOS cloud image with pre-installed cloud-init you should follow this guide:
`CentOS cloud image. <http://docs.openstack.org/image-guide/content/centos-image.html>`_ Use the latest version of cloud-init package from `testing repository <http://pkgs.org/centos-6/epel-testing-i386/cloud-init-0.7.4-2.el6.noarch.rpm.html>`_

In the end you should check installation of cloud-init package.

You should mount your image and check some files. Follow this example to mount cloud image using qemu:

.. sourcecode:: bash

  sudo modprobe nbd max_part=63
  sudo qemu-nbd -c /dev/nbd0 CentOS_image_name.qcow2
  sudo partprobe /dev/nbd0
  sudo mount /dev/nbd0p1 /mnt/qemu
  sudo chroot /mnt/qemu

Check files:

1. File '/etc/cloud/cloud.cfg' should contain these lines:

.. sourcecode:: cfg

  default_user:
     name: cloud-user
     lock_passwd: true
     gecos: CentOS Cloud User
     groups: [wheel, adm]
     sudo: ["ALL=(ALL) NOPASSWD:ALL"]
     shell: /bin/bash

Add them if they are not exist.

2. File '/etc/fstab'. Check that fifth and sixth fields contain value '0'.
