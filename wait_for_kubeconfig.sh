#!/bin/sh

echo "waiting for cluster kubeconfig to be ready..."
while true; do { kubectl get secret capg-pathtoprod-kubeconfig 2>/dev/null; test $? == 0 && break; } done
echo "kubeconfig is ready now."