#!/bin/bash

mkdir -p /etc/kubernetes/config

{
  chmod +x kube-apiserver   \
    kube-controller-manager \
    kube-scheduler kubectl

  mv kube-apiserver         \
    kube-controller-manager \
    kube-scheduler kubectl  \
    /usr/local/bin/
}

{
  mkdir -p /var/lib/kubernetes/

  mv ca.crt ca.key                            \
    kube-api-server.key kube-api-server.crt   \
    service-accounts.key service-accounts.crt \
    encryption-config.yaml                    \
    /var/lib/kubernetes/
}

mv kube-apiserver.service \
  /etc/systemd/system/kube-apiserver.service
mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
mv kube-controller-manager.service /etc/systemd/system/
mv kube-scheduler.kubeconfig /var/lib/kubernetes/
mv kube-scheduler.yaml /etc/kubernetes/config/
mv kube-scheduler.service /etc/systemd/system/

{
  systemctl daemon-reload

  systemctl enable --now kube-apiserver \
    kube-controller-manager kube-scheduler
}

sleep 5

kubectl cluster-info \
  --kubeconfig admin.kubeconfig

kubectl apply -f kube-apiserver-to-kubelet.yaml \
  --kubeconfig admin.kubeconfig

