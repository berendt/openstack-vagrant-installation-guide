#!/bin/sh

set -x

###################################################################################################
###################################################################################################
# PREPARATIONS

yum install -y epel-release
yum update -y
yum install -y crudini vim sshpass
if [[ ! -e /root/.ssh/id_rsa ]]; then
    ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
fi
for node in $(sed -n '/## vagrant-hostmanager-start/{:a;n;/## vagrant-hostmanager-end/b;p;ba}' /etc/hosts | awk '{ print $2 }'); do
    ssh-keyscan $node >> /root/.ssh/known_hosts
    sshpass -pvagrant ssh root@$node "mkdir -p /root/.ssh"
    sshpass -pvagrant ssh root@$node "chmod 700 /root/.ssh"
    sshpass -pvagrant scp /root/.ssh/id_rsa.pub root@$node:/root/.ssh/authorized_keys
done

###################################################################################################
###################################################################################################
# NTP

yum install -y ntp
cat <<EOT >> /etc/ntp.conf
restrict -4 default kod notrap nomodify
restrict -6 default kod notrap nomodify
EOT
systemctl enable ntpd.service
systemctl start ntpd.service

sleep 15

ntpq -c peers
ntpq -c assoc

###################################################################################################
###################################################################################################
# RDO REPOSITORY

yum install -y epel-release
yum install -y http://rdoproject.org/repos/openstack-kilo/rdo-release-kilo.rpm

# NOTE(berendt): Workaround until the completion of the RDO Kilo repository.
cd /etc/yum.repos.d; wget http://trunk.rdoproject.org/centos70/latest-RDO-trunk-CI/delorean.repo

yum upgrade -y

###################################################################################################
###################################################################################################
# SELINUX

yum install -y openstack-selinux
