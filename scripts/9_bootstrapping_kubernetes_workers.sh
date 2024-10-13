#!/bin/bash

{
  apt-get update
  apt-get -y install socat conntrack ipset
}

swapoff -a

mkdir -p              \
  /etc/cni/net.d      \
  /opt/cni/bin        \
  /var/lib/kubelet    \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

{
  mkdir -p containerd
  tar -xvf crictl-*.tar.gz
  tar -xvf containerd-*.tar.gz     -C containerd
  tar -xvf cni-plugins-linux-*.tgz -C /opt/cni/bin/
  mv runc.* runc
  chmod +x crictl kubectl kube-proxy kubelet runc
  mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  mv containerd/bin/* /bin/
}

mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/

{
  mkdir -p /etc/containerd/
  mv containerd-config.toml /etc/containerd/config.toml
  mv containerd.service /etc/systemd/system/
}

{
  mv kubelet-config.yaml /var/lib/kubelet/
  mv kubelet.service /etc/systemd/system/
}

{
  mv kube-proxy-config.yaml /var/lib/kube-proxy/
  mv kube-proxy.service /etc/systemd/system/
}

{
  systemctl daemon-reload
  systemctl enable containerd kubelet kube-proxy
  systemctl start containerd kubelet kube-proxy
}
