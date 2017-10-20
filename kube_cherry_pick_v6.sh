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

set -o errexit
set -o pipefail

working_dir=$GOPATH/src/k8s.io/kubernetes

function usage {
    echo "usage: $0 [-h | --help ] [-u | --update-master] [-b branch-name | --branch branch-name]"
    echo "  -h,--help                 Display help"
    echo "  -u,--upstream-rebase      Rebase to upstream master"
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
    -u|--upstream-rebase)
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

# Start out in working directory
cd $working_dir

# Create branch if requested
if [[ $BRANCH ]]; then
    git checkout -b $BRANCH
fi

# Rebase to upstream master if requested
if [[ $UPDATE ]]; then
    git fetch upstream
    git rebase upstream/master
fi

# Add contributor remotes if necessary, and disable direct commits
if ! git remote | grep rpothier > /dev/null; then
  git remote add rpothier https://github.com/rpothier/kubernetes.git
  git remote set-url --push rpothier no_push
fi
if ! git remote | grep pmichali > /dev/null; then
  git remote add pmichali https://github.com/pmichali/kubernetes.git
  git remote set-url --push pmichali no_push
fi
if ! git remote | grep danehans > /dev/null; then
  git remote add danehans https://github.com/danehans/kubernetes.git
  git remote set-url --push danehans no_push
fi
if ! git remote | grep leblancd > /dev/null; then
  git remote add leblancd https://github.com/leblancd/kubernetes.git
  git remote set-url --push leblancd no_push
fi

# Cherry pick IPv6-related pull requests
counter=0

# REQUIRED FOR IPv6 e2e TEST SUITE
# "Add kubeadm config for setting kube-proxy bind address"
# https://github.com/kubernetes/kubernetes/pull/50929
git fetch leblancd v6_kubeadm_proxy && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# "Adds Support for Configurable Kubeadm Probes"
# https://github.com/kubernetes/kubernetes/pull/53484
git fetch danehans kubeadm_probe && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# "Adds Support for Node Resource IPv6 Addressing"
# https://github.com/kubernetes/kubernetes/pull/45551
git fetch danehans node_v6 && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# "ip6tables should be set in the noop plugin"
# https://github.com/kubernetes/kubernetes/pull/53148
git fetch rpothier plugins-ipv6 && git cherry-pick FETCH_HEAD
counter=$((counter+1))

##### NEEDS REBASE - REBASED AND PUSHED TO leblancd github ########
# "Kubeadm should check for bridge-nf-call-ip6tables"
# https://github.com/kubernetes/kubernetes/pull/53014
# git fetch upstream && git cherry-pick 1a84e55
git fetch leblancd v6_robs_53014 && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# "Updating kubenet for CNI with IPv6"
# https://github.com/kubernetes/kubernetes/pull/52180
git fetch rpothier Kubenet-for-CNIv6 && git cherry-pick FETCH_HEAD
counter=$((counter+1))

##### NEEDS REBASE - REBASED AND PUSHED TO leblancd github ########
# "Updating NewCIDRSet return a value"
# https://github.com/kubernetes/kubernetes/pull/45792
# git fetch upstream && git cherry-pick 433a851
git fetch leblancd v6_robs_45792 && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# REQUIRED FOR IPv6 e2e TEST SUITE
# "Fallback to internal addrs in e2e tests when no external addrs available"
# https://github.com/kubernetes/kubernetes/pull/53569
git fetch leblancd v6_e2e_ext_ip && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# "Add IPv6 and negative UT test cases for proxier's deleteEndpointConnections"
# https://github.com/kubernetes/kubernetes/pull/53555
git fetch leblancd v6_del_endpoint_proxier && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# REQUIRED FOR IPv6 e2e TEST SUITE
# "Add brackets around IPv6 addrs in e2e test IP:port endpoints"
# https://github.com/kubernetes/kubernetes/pull/52748
git fetch leblancd v6_e2e_host_port && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# "Hack to leave conntrack max per core zero, so that later..."
# https://github.com/pmichali/kubernetes/tree/ipv4-ipv6
git fetch pmichali ipv4-ipv6 && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# REQUIRED FOR IPv6 e2e TEST SUITE
# "kube-dns IPv6 changes and use type SRV sidecar probes"
# https://github.com/leblancd/kubernetes/tree/v6_dns_probes
git fetch leblancd v6_dns_probes && git cherry-pick FETCH_HEAD
counter=$((counter+1))

# Display results:
echo Cherry-picked change sets:
git log --oneline | head -n $counter

