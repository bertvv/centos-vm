#! /usr/bin/bash
#
# Author:   Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# This installs VirtualBox's Guest Additions on systems that suffer from
# this bug: https://www.virtualbox.org/ticket/12638

set -u # abort on unbound variable
set -x # Debug output

vb_version=$(cat /home/vagrant/.vbox_version)
iso=VBoxGuestAdditions_${vb_version}.iso

epel=https://dl.fedoraproject.org/pub/epel/beta/7/x86_64/epel-release-7-0.2.noarch.rpm

# Install prerequisites
yum install -y ${epel}
yum install -y patch dkms

# Download Guest Additions Installer
if [ ! -f ${iso} ]; then
  wget http://download.virtualbox.org/virtualbox/4.3.12/VBoxGuestAdditions_4.3.12.iso
fi
mount -o loop ${iso} /mnt
/mnt/VBoxLinuxAdditions.run --noexec --keep
umount /mnt

# Apply patch
cur_dir=$(pwd)
tmp_dir=$(mktemp -d)
patch=VBox-numa_no_reset.diff
cat > ${patch} << _EOF_
Index: src/vboxguest-${vb_version}/vboxguest/r0drv/linux/memobj-r0drv-linux.c
===================================================================
--- src/vboxguest-${vb_version}/vboxguest/r0drv/linux/memobj-r0drv-linux.c (Revision 50574)
+++ src/vboxguest-${vb_version}/vboxguest/r0drv/linux/memobj-r0drv-linux.c (Arbeitskopie)
@@ -66,6 +66,18 @@
 #endif
 
 
+/*
+ * Distribution kernels like to backport things so that we can't always rely
+ * on Linux kernel version numbers to detect kernel features.
+ */
+#ifdef CONFIG_SUSE_KERNEL
+# if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 12, 0)
+# define NUMA_NO_RESET
+# endif
+#elif LINUX_VERSION_CODE < KERNEL_VERSION(3, 13, 0)
+# define NUMA_NO_RESET
+#endif
+
 /*******************************************************************************
 *   Structures and Typedefs                                                    *
 *******************************************************************************/
@@ -1533,12 +1545,12 @@
                 /** @todo Ugly hack! But right now we have no other means to disable
                  *        automatic NUMA page balancing. */
 # ifdef RT_OS_X86
-#  if LINUX_VERSION_CODE < KERNEL_VERSION(3, 13, 0)
+#  ifndef NUMA_NO_RESET
                 pTask->mm->numa_next_reset = jiffies + 0x7fffffffUL;
 #  endif
                 pTask->mm->numa_next_scan  = jiffies + 0x7fffffffUL;
 # else
-#  if LINUX_VERSION_CODE < KERNEL_VERSION(3, 13, 0)
+#  ifndef NUMA_NO_RESET
                 pTask->mm->numa_next_reset = jiffies + 0x7fffffffffffffffUL;
 #  endif
                 pTask->mm->numa_next_scan  = jiffies + 0x7fffffffffffffffUL;
_EOF_

tarball=${cur_dir}/install/VBoxGuestAdditions-amd64.tar.bz2

cd ${tmp_dir}
tar xjf ${tarball}
patch -p0 < ${cur_dir}/${patch}
tar cjf ${tarball} *

# Run installer
cd ${cur_dir}/install
./install.sh

# Clean up
cd ..
echo "==> Removing packages needed for building guest tools"
rm -rf ${tmp_dir}
rm -rf ${cur_dir}/install
rm -rf ${cur_dir}/${patch}
rm -rf ${cur_dir}/${iso}
rm -rf /home/vagrant/.vbox_version

yum remove -y bzip2 gcc cpp kernel-devel kernel-headers perl patch

exit 0
