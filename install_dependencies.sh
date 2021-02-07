#!/bin/bash

# Download HammerDB
wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz
tar -xf HammerDB-4.0-Linux.tar.gz 

# Install moreutils
sudo yum install moreutils -y

# Make pgtcl working
# https://techviewleo.com/install-postgresql-12-on-amazon-linux/
sudo yum -y update
sudo amazon-linux-extras | grep postgre

sudo tee /etc/yum.repos.d/pgdg.repo<<EOF
[pgdg12]
name=PostgreSQL 12 for RHEL/CentOS 7 - x86_64
baseurl=https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-7-x86_64
enabled=1
gpgcheck=0
EOF

sudo yum makecache -y

sudo yum install postgresql12 -y

# Install tcl interpreter
sudo yum install tcl -y