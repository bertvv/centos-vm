#!/bin/bash -eux
#
# Enable Yum repositories for CentOS QA release
# See http://seven.centos.org/2014/06/centos-7-public-qa-release/

echo '==> Enabling CentOS Buildlogs QA repos'

cat > /etc/yum.repos.d/centos-buildlogs.repo << _EOF_
[centos-qa-03]
name=CentOS Open QA – c7.00.03
baseurl=http://buildlogs.centos.org/c7.00.03/
enabled=1
gpgcheck=0

[centos-qa-04]
name=CentOS Open QA – c7.00.04
baseurl=http://buildlogs.centos.org/c7.00.04/
enabled=1
gpgcheck=0
_EOF_

