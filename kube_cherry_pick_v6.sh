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
git pull upstream pull/47621/head
counter=$((counter+1))

# "Add kubeadm config for setting kube-proxy bind address"
git pull upstream pull/50929/head
counter=$((counter+1))

# "Fix kube-proxy to use proper iptables commands for IPv6"
git pull upstream pull/50478/head
counter=$((counter+1))

# "Removed the IPv6 prefix size limit for cluster-cidr"
git pull upstream pull/52033/head
counter=$((counter+1))

# "Adds Support for Configurable Kubeadm Probes"
git pull upstream pull/head/53484
counter=$((counter+1))

# "Adds Support for Node Resource IPv6 Addressing"
git pull upstream pull/head/45551
counter=$((counter+1))

# "kubenet: do not generate HW addr for IPv6"
git pull upstream pull/head/48729
counter=$((counter+1))

# "ip6tables should be set in the noop plugin"
git pull upstream pull/head/53148
counter=$((counter+1))

# "Kubeadm should check for bridge-nf-call-ip6tables"
git pull upstream pull/head/53014
counter=$((counter+1))

# "Updating kubenet for CNI with IPv6"
git pull upstream pull/head/52180
counter=$((counter+1))

# "Updating NewCIDRSet return a value"
git pull upstream pull/head/45792
counter=$((counter+1))

# "Fix duplicate unbind action in kube-proxy"
git pull upstream pull/head/51686
counter=$((counter+1))

# "Fallback to internal addrs in e2e tests when no external addrs available"
git pull upstream pull/head/53569
counter=$((counter+1))

# "Fix IP calculation for IPv6 in proxier's deleteEndpointConnections"
git pull upstream pull/head/53555
counter=$((counter+1))

# "Add brackets around IPv6 addrs in e2e test IP:port endpoints"
git pull upstream pull/head/52748
counter=$((counter+1))

# "kube-dns IPv6 changes and use type SRV sidecar probes"
git remote add leblancd https://github.com/leblancd/$repo.git
git remote set-url --push leblancd no_push
git fetch leblancd v6_dns_probes && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# Display results:
echo Cherry-picked change sets:
git log --oneline | head -n $counter

