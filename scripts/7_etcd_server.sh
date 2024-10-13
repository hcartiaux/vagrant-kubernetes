#!/bin/bash

{
  etcdpkg="$(echo -n -e etcd-*.tar.gz)"
  tar -xvf "$etcdpkg"
  mv $(basename "$etcdpkg" .tar.gz)/etcd* /usr/local/bin/
}

{
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 700 /var/lib/etcd
  cp ca.crt kube-api-server.key kube-api-server.crt \
    /etc/etcd/
}

mv etcd.service /etc/systemd/system/

{
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
}

etcdctl member list
