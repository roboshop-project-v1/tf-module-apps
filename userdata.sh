#!/bin/bash


yum install ansible -y &>>/opt/userdata.log
ansible-pull -i localhost, -U https://github.com/roboshop-project-v1/roboshop-ansible.git main.yml -e component=${component} &>>/opt/userdata.log
