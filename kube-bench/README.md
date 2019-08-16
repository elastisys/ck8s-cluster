## Kube-bench

### General notes

Kube bench is basically the cni kubernetes benchmark copied into a test framework.

It is esiest to run as a docker container on the node that you are testing (see below for instructions).
However the benchmark is not designed for rke, but rather things like kubeadm or kubespray. It also relies on a few normal linux tools that RancherOS does not have installed. Because of this kube-bench will not work properly for us out of the box. One can change the config that specifies the tests in order to make them work (some work has been done with this, cfg/1.13/master.yaml and cfg/1.13/node.yaml). But there are still some tests that will not be applicable, since the installation process is different and the controlplane is not running as pods in the cluster.

We need to figure out if it's worth fully fixing the test to suit rke and/or changing our setup to pass the tests. Many tests are about having the right flags set on the different control plane components, which is rather easy to fix, though some might interfere with the rest of the installation. Some tests are about having the correct permissions on files at the nodes, which is a bit harder to fix and some are not applicable. Then there are some more general tests that are hard to have general scripts for and therefore need manual testing (e.g. 'Do not admit privileged containers')

### Running kube-bench

First move the relevant config to the node.

```
scp cfg/1.13/master.yaml rancher@<node ip>:/home/rancher/master.yaml
```
or
```
scp cfg/1.13/node.yaml rancher@<node ip>:/home/rancher/node.yaml
```

Then run the container with the relevant config

```
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v /home/rancher/master.yaml:/opt/kube-bench/cfg/1.13/master.yaml -t aquasec/kube-bench:latest master --version 1.13
```
or
```
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v /home/rancher/node.yaml:/opt/kube-bench/cfg/1.13/node.yaml -t aquasec/kube-bench:latest node --version 1.13
```

### Relevant links
Kube-bench github: https://github.com/aquasecurity/kube-bench

CNI kubernetes benchmark: https://www.cisecurity.org/benchmark/kubernetes/

Rancher documentation about hardening, info about some points from the CNI benchmark: https://rancher.com/docs/rancher/v2.x/en/security/hardening-2.2/