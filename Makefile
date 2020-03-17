GO111MODULE=GO111MODULE=on
GOCMD=$(GO111MODULE) go
MANAGER_CLUSTER=kind-clusterapi

pre-reqs:
	$(GOCMD) env

	# kind
	$(GOCMD) get sigs.k8s.io/kind@v0.7.0

	# clusterctl
	cd $(HOME)/bin && \
		curl -LO https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.0/clusterctl-darwin-amd64 && \
		chmod 700 ./clusterctl-darwin-amd64 && \
		ln -sf $(HOME)/bin/clusterctl-darwin-amd64 $(HOME)/bin/clusterctl
	
	# clusterawsadm
	cd $(HOME)/bin && \
		 curl -LO https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.4.10/clusterawsadm-darwin-amd64 && \
		 chmod 700 ./clusterawsadm-darwin-amd64 && \
		 ln -sf $(HOME)/bin/clusterawsadm-darwin-amd64 $(HOME)/bin/clusterawsadm

# 
# create local management cluster
# 
manager:
	# TODO waiting on https://github.com/kubernetes-sigs/cluster-api/pull/2684 for GCP infra provider
	clusterctl config provider --infrastructure aws
	clusterctl init --infrastructure=aws

switch-to-manager:
	kubectx $(MANAGER_CLUSTER)

# # # # # # # # # # # # # # # # # # # # # 
# GCP
# # # # # # # # # # # # # # # # # # # # # 
gcp-cluster: switch-to-manager
	kubectl apply -f ./manifests/workload/gcp/capg-cluster.yaml
	make gcp-controlplane
	./wait_for_infra_provisioning.sh "capg-pathtoprod"
	
	./wait_for_kubeconfig.sh "capg-pathtoprod"
	make gcp-kubeconfig
	
	./wait_for_apiserver.sh "gcp-pathtoprod.kubeconfig"
	
	make gcp-cni
	./wait_for_cni.sh

	make gcp-workers

gcp-controlplane:
	kubectl apply -f ./manifests/workload/gcp/capi-controlplane.yaml
	kubectl get machines --selector cluster.x-k8s.io/control-plane

gcp-cni:
	kubectl --kubeconfig=./gcp-pathtoprod.kubeconfig apply -f ./manifests/workload/cni.yaml

gcp-workers:
	cat ./manifests/workload/gcp/capi-worker-nodes.yaml \
		| envsubst \
		| kubectl apply -f -

gcp-kubeconfig:
	kubectl --context=$(MANAGER_CLUSTER) get secret capg-pathtoprod-kubeconfig -o json | jq -r .data.value | base64 -D > ./gcp-pathtoprod.kubeconfig
	./install_kubeconfig.sh "gcp-pathtoprod.kubeconfig"

gcp-destroy:
	-kubectl delete --kubeconfig=./gcp-pathtoprod.kubeconfig --ignore-not-found -f ./manifests/workload/cni.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/gcp/capi-worker-nodes.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/gcp/capi-controlplane.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/gcp/capg-cluster.yaml

# # # # # # # # # # # # # # # # # # # # # 
# AWS
# # # # # # # # # # # # # # # # # # # # # 
aws-cluster: switch-to-manager
	kubectl apply -f ./manifests/workload/aws/capa-cluster.yaml
	make aws-controlplane
	./wait_for_infra_provisioning.sh "capa-pathtoprod"

	./wait_for_kubeconfig.sh "capa-pathtoprod"
	make aws-kubeconfig

	./wait_for_apiserver.sh "aws-pathtoprod.kubeconfig"

aws-controlplane:
	kubectl --context=$(MANAGER_CLUSTER) apply -f ./manifests/workload/aws/capa-controlplane.yaml
	kubectl get machines -l cluster.x-k8s.io/cluster-name=capa-pathtoprod -o json | jq -r ".items[].status"

aws-kubeconfig:
	kubectl --context=$(MANAGER_CLUSTER) get secret capa-pathtoprod-kubeconfig -o json | jq -r .data.value | base64 -D > ./aws-pathtoprod.kubeconfig
	./install_kubeconfig.sh "aws-pathtoprod.kubeconfig"

aws-destroy: switch-to-manager
	# -kubectl delete --kubeconfig=./gcp-pathtoprod.kubeconfig --ignore-not-found -f ./manifests/workload/cni.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/aws/capa-worker-nodes.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/aws/capa-controlplane.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/aws/capa-cluster.yaml