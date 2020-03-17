#!/bin/sh
set -u

CLUSTER=$1

echo "waiting for cluster $CLUSTER to match infrastructureReady=true..."
while true; do { test "$(kubectl get cluster $CLUSTER -o json | jq -r .status.infrastructureReady)" = "true" && break; } done

echo "waiting for machines of $CLUSTER to match infrastructureReady=true..."
while true; do { test "$(kubectl get machines -l cluster.x-k8s.io/cluster-name=$CLUSTER -o json | jq -r 'all(.items[].status.infrastructureReady; true )')" = "true" && break; } done

echo "$CLUSTER infrastructure is ready now."
