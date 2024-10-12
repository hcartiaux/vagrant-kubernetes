#!/bin/bash

sed -i \
  's/^#PermitRootLogin.*/PermitRootLogin yes/' \
  /etc/ssh/sshd_config

systemctl restart sshd

cp /vagrant/ssh/id_rsa{.pub,} /root/.ssh/
chown root: /root/.ssh/id_rsa{.pub,}
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
