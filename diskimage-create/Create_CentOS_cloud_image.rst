This element setups our CentOS cloud image (http://savanna-files.mirantis.com/CentOS-6.4-cloud-init.qcow2):
1. Disable filesystem checks;
2. Use specifies for CentOS only map-package and install-package files;
3. Install redhat-lsb package for using command `lsb_release`.

For preparing your own CentOS cloud image with pre-installed cloud-init you should follow this guide:
`CentOS cloud image <http://docs.openstack.org/grizzly/openstack-image/content/centos-image.html>`_

In the end you should check installation of cloud-init packege.

You should mount your image and check some files. Follow this example to mount cloud image using qemu:

.. sourcecode:: bash

  sudo modprobe nbd max_part=63
  sudo qemu-nbd -c /dev/nbd0 CentOS_image_name.qcow2
  sudo partprobe /dev/nbd0
  sudo mount /dev/nbd0p1 /mnt/qemu
  sudo chroot /mnt/qemu

Check files:

1. File '/etc/cloud/cloud.cfg' should contain these lines:

default_user:
   name: cloud-user
   lock_passwd: true
   gecos: CentOS Cloud User
   groups: [wheel, adm]
   sudo: ["ALL=(ALL) NOPASSWD:ALL"]
   shell: /bin/bash

Add them if they are not exist.

2. File '/etc/fstab'. Check that fifth and sixth fields contain value '0'.
