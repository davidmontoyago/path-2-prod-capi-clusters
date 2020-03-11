#!/bin/sh
#
# installs a given kubeconfig
#

NEW_KUBECONFIG_FILE=$1

KCONFIG=$HOME/.kube/config
STAMP=$(date '+%Y-%m-%d-%H%M%S')
PWD=$(pwd)

cp "$KCONFIG" "$KCONFIG-backup-$STAMP"
KUBECONFIG="$KCONFIG:$PWD/$NEW_KUBECONFIG_FILE" kubectl config view --merge --flatten > ./tmp
mv ./tmp $KCONFIG