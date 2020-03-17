#!/bin/sh
set -u

CLUSTER_KUBECONFIG=$1

echo "waiting for apiserver to be ready..."

while true; do { sleep 1; kubectl --kubeconfig=$CLUSTER_KUBECONFIG cluster-info 1>/dev/null 2>/dev/null; test $? == 0 && break; } done

echo "apiserver is ready now."