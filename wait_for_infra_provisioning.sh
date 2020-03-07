#!/bin/sh

echo "waiting for cluster infrastructureReady=true..."
while true; do { test "$(kubectl get cluster capg-pathtoprod -o json | jq -r .status.infrastructureReady)" = "true" && break; } done
echo "infrastructure is ready now."
