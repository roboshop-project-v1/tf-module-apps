#!/bin/bash

sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install ansible  -y &>>/opt/userdata.log
/usr/bin/python3.12 -m ensurepip
/usr/bin/python3.12 -m pip install --upgrade pip
/usr/bin/python3.12 -m pip install botocore boto3  &>>/opt/userdata.log
ansible-pull -i localhost, -U https://github.com/roboshop-project-v1/roboshop-ansible.git main.yml -e component=${component} -e env=${env} &>>/opt/userdata.log
