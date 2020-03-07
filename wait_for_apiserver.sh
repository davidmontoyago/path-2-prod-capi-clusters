#!/bin/sh

echo "waiting for apiserver to be ready..."
while true; do { kubectl --kubeconfig=./gcp-pathtoprod.kubeconfig cluster-info 1>/dev/null 2>/dev/null; test $? == 0 && break; } done
echo "apiserver is ready now."