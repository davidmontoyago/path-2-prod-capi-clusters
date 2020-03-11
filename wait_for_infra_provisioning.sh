#!/bin/sh

CLUSTER=$1

echo "waiting for cluster $CLUSTER to match infrastructureReady=true..."
while true; do { test "$(kubectl get cluster $CLUSTER -o json | jq -r .status.infrastructureReady)" = "true" && break; } done
echo "$CLUSTER infrastructure is ready now."
