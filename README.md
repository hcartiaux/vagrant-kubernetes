### My Vagrant configuration for [Kelsey Hightower's tutorial "Kubernetes The Hard Way"](https://github.com/kelseyhightower/kubernetes-the-hard-way)

This vagrant configuration will set-up a Kubernetes cluster following Kelsey Hightower's instructions, from [Section 1](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md) to [Section 11](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/11-pod-network-routes.md).

Place yourself in this directory and run `vagrant up`.

You can now jump to [Section 12](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/12-smoke-test.md) and manipulate the Kubernetes cluster.

```
# vagrant ssh jumpbox
# sudo su -
# kubectl get nodes
NAME     STATUS   ROLES    AGE   VERSION
node-0   Ready    <none>   35m   v1.28.3
node-1   Ready    <none>   35m   v1.28.3
```
