#!/bin/sh

echo "waiting for CNI to be ready..."
sleep 5s
kubectl --kubeconfig=./gcp-pathtoprod.kubeconfig -n kube-system wait --for=condition=Ready pod -l k8s-app=calico-kube-controllers
echo "CNI is ready."