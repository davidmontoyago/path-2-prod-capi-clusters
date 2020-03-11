#!/bin/sh

CLUSTER=$1

echo "waiting for cluster kubeconfig to be ready..."
while true; do { kubectl get secret $CLUSTER-kubeconfig 2>/dev/null; test $? == 0 && break; } done
echo "kubeconfig is ready now."