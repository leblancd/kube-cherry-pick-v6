# kube-cherry-pick-v6
Bash script for cherry picking outstanding Kubernetes pull requests
that are necessary for Kubernetes cluster IPv6 operation.

```
usage: kube_v6_cherry_pick.sh [-h | --help ] [-u | --update-master] [-b branch-name | --branch branch-name]
  -h,--help                 Display help
  -u,--update-master        Update master branch
  -b,--branch branch-name   Create local branch with specified name
```

After cherry-picking these diffs, you'll want to build Kubernetes
binaries and container images, and push the container images to
a public or local registry for kubeadm init/join to pick up.

Note: If you plan on using kube-proxy services with IPv6 service
addresses, then you'll want to run 'kubeadm init ...' with a config
file that sets the kube-proxy bind address to ::0, e.g.:

```
    cat << EOT >> kubeadm_v6.cfg
    apiVersion: kubeadm.k8s.io/v1alpha1
    kind: MasterConfiguration
    api:
      advertiseAddress: <YOUR-KUBE-MASTER-IPv6-ADDRESS>
    kubeProxy:
      bindAddress: ::0
    etcd:
      image: diverdane/etcd-amd64:3.0.17
    networking:
      serviceSubnet: fd00:1234::/110
    imageRepository: <YOUR-DOCKER-REGISTRY>
    kubernetesVersion: v1.8.0
    tokenTTL: 0
    nodeName: kube-master
    EOT
```

When you are ready to start up your Kubernetes master node, the command would be:

```
    kubeadm init --config=kubeadm_v6.cfg
```

