#!/bin/bash

################################################################
# Shell script for cherry-picking outstanding (i.e. non-merged)
# Kubernetes pull request changes that are critical to IPv6
# functionality in a Kubernetes cluster.
#
# This utility assumes that $GOPATH is set for proper Go
# compilation and that Kubernetes project
# (https://github.com/kubernetes/kubernetes) has been cloned
# to $GOPATH/src/k8s.io/kubernetes.
################################################################

repo=kubernetes
working_dir=$GOPATH/src/k8s.io/$repo

function usage {
    echo "usage: $0 [-h | --help ] [-u | --update-master] [-b branch-name | --branch branch-name]"
    echo "  -h,--help                 Display help"
    echo "  -u,--update-master        Update master branch"
    echo "  -b,--branch branch-name   Create local branch with specified name"
    exit 1
}

# Process command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    HELP=true
    ;;
    -b|--branch)
    BRANCH="$2"
    shift # past argument
    ;;
    -u|--update-master)
    UPDATE=true
    ;;
    *)
    HELP=true   # Unknown option
    ;;
esac
shift # past argument or value
done

# Display usage information if requested
if [[ $HELP ]]; then usage; fi

# Update master branch if requested
if [[ $UPDATE ]]; then
    cd $working_dir
    git checkout master
    git fetch upstream
    git rebase upstream/master
fi

if [[ $BRANCH ]]; then
    git checkout -b $BRANCH
fi

# Cherry pick IPv6-related pull requests
counter=0

# "Updates RangeSize error message and tests for IPv6"
curl https://patch-diff.githubusercontent.com/raw/kubernetes/kubernetes/pull/47621.patch | git am
counter=$((counter+1))

# "Add IPv6 support to iptables proxier"
curl https://patch-diff.githubusercontent.com/raw/kubernetes/kubernetes/pull/48551.patch | git am
counter=$((counter+1))

# "Add kubeadm config for setting kube-proxy bind address"
curl https://patch-diff.githubusercontent.com/raw/kubernetes/kubernetes/pull/50929.patch | git am
counter=$((counter+1))

# "Fix kube-proxy to use proper iptables commands for IPv6"
curl https://patch-diff.githubusercontent.com/raw/kubernetes/kubernetes/pull/50478.patch | git am
counter=$((counter+1))

# "Add required family flag for conntrack IPv6 operation"
curl https://patch-diff.githubusercontent.com/raw/kubernetes/kubernetes/pull/52028.patch | git am
counter=$((counter+1))

# "Removed the IPv6 prefix size limit for cluster-cidr"
curl https://patch-diff.githubusercontent.com/raw/kubernetes/kubernetes/pull/52033.patch | git am
counter=$((counter+1))

# "kube-dns IPv6 changes and use type SRV sidecar probes"
git remote add leblancd https://github.com/leblancd/$repo.git
git remote set-url --push leblancd no_push
git fetch leblancd v6_dns_probes && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# Display results:
echo Cherry-picked change sets:
git log --oneline | head -n $counter

