We have CentOS 6.4 and 6.5 cloud images. Recommended is CentOS 6.5 (http://sahara-files.mirantis.com/CentOS-6.5-cloud-init.qcow2).

Prepare your own CentOS cloud image:

1. Create disk image with qcow2 format

.. sourcecode:: bash

  qemu-img create -f qcow2 -o preallocation=metadata /tmp/centos-6-cloud.qcow2 2G

2. Install CentOS, You should use one partition and no swap. Get netinstall ISO from http://isoredirect.centos.org/centos/6/isos/x86_64/.

.. sourcecode:: bash

  virt-install --name=centos-6-cloud --disk path=/tmp/centos-6-cloud.qcow2,format=qcow2 -r 1024 --vcpus=1 --hvm -c /tmp/CentOS-6.5-x86_64-netinstall.iso

3. Login into your new image and modify '/etc/sysconfig/network-scripts/ifcfg-eth0' to look like this

.. sourcecode:: bash

  DEVICE="eth0"
  BOOTPROTO="dhcp"
  NM_CONTROLLED="no"
  ONBOOT="yes"
  TYPE="Ethernet"

4. Add EPEL repository and update OS

.. sourcecode:: bash

  wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  rpm -ivh epel-release-6-8.noarch.rpm

5. Install cloud-utils and cloud-init

.. sourcecode:: bash

  yum install cloud-utils, cloud-init

6. Download 'centos-image-mod.sh' and 'init-part' together in same directory, run 'centos-image-mod.sh'. This will modify initrd and grub.conf.

.. sourcecode:: bash

  git clone https://github.com/jaryn/centos-image-resize
  cd centos-image-resize && ./centos-image-mod.sh

6.1. Edit '/boot/grub/grub.conf', check if everything is OK. Also, may not be a bad idea to set timeout to 0.

7. Delete '/etc/udev/rules.d/70-persistent-net.rules', this will be auto created during boot. Don't forget this, since you won't have functional network when you bring this image up on Openstack.

8. Check files:

  File '/etc/cloud/cloud.cfg' should contain these lines:

.. sourcecode:: cfg

  default_user:
     name: cloud-user
     lock_passwd: true
     gecos: CentOS Cloud User
     groups: [wheel, adm]
     sudo: ["ALL=(ALL) NOPASSWD:ALL"]
     shell: /bin/bash

Add them if they are not exist.

  File '/etc/fstab'. Check that fifth and sixth fields contain value '0'.

9. Power down your virtual Centos

10. Compress qcow2 image with

.. sourcecode:: bash

  qemu-img convert -c /tmp/centos-6-cloud.qcow2 -O qcow2 /tmp/centos.qcow2


Image /tmp/centos.qcow2 is now ready for upload to Openstack

`Source for this doc <http://lists.openstack.org/pipermail/openstack-operators/2013-June/003131.html>`_
