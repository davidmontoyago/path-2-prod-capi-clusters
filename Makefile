GO111MODULE=GO111MODULE=on
GOCMD=$(GO111MODULE) go
MANAGER_CLUSTER=kind-clusterapi

pre-reqs:
	$(GOCMD) env

	# kind
	$(GOCMD) get sigs.k8s.io/kind@v0.7.0
	
	# clusterawsadm
	cd $(HOME)/bin && \
		 curl -LO https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.4.10/clusterawsadm-darwin-amd64 && \
		 chmod 700 ./clusterawsadm-darwin-amd64 && \
		 ln -sf $(HOME)/bin/clusterawsadm-darwin-amd64 $(HOME)/bin/clusterawsadm


#
# get cluster api and bootstrap provider manifests
# 
capi-manifests:
	# cluster api 
	curl -L -o ./manifests/management/cluster-api-components.yaml https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.2.10/cluster-api-components.yaml
	curl -L -o ./manifests/management/bootstrap-components.yaml https://github.com/kubernetes-sigs/cluster-api-bootstrap-provider-kubeadm/releases/download/v0.1.6/bootstrap-components.yaml
	# cert manageer
	curl -L -o ./manifests/management/cert-manager.yaml https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml
	
	make provider-manifests

# 
# get gcp infra provider manifests
# 
gcp-provider-manifest:
	curl -L -o ./manifests/management/capg/infrastructure-components.yaml https://github.com/kubernetes-sigs/cluster-api-provider-gcp/releases/download/v0.2.0-alpha.2/infrastructure-components.yaml

#
# get aws infra provider manifests
#
aws-provider-manifest:
	curl -L -o ./manifests/management/capa/infrastructure-components.yaml https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.4.9/infrastructure-components.yaml

provider-manifests:
	make gcp-provider-manifest
	make aws-provider-manifest

# 
# create local management cluster
# 
manager:
	kubectl apply -f manifests/management/cert-manager.yaml
	kubectl wait --for=condition=Available --timeout=300s apiservice v1beta1.webhook.cert-manager.io
	kubectl apply -f manifests/management/cluster-api-components.yaml
	kubectl apply -f manifests/management/bootstrap-components.yaml

# 
# install gcp infra provider
# 
gcp-provider:
	cat ./manifests/management/capg/infrastructure-components.yaml \
  		| envsubst \
  		| kubectl apply -f -

aws-provider:
	cat ./manifests/management/capa/infrastructure-components.yaml \
		| envsubst \
		| kubectl apply -f -

#
# deploy gcp capi cluster
#
gcp-cluster:
	kubectl apply -f ./manifests/workload/gcp/capg-cluster.yaml
	make gcp-controlplane
	./wait_for_infra_provisioning.sh "capg-pathtoprod"
	
	./wait_for_kubeconfig.sh "capg-pathtoprod"
	make gcp-kubeconfig
	
	./wait_for_apiserver.sh
	
	make gcp-cni
	./wait_for_cni.sh

	make gcp-workers

#
# deploy gcp control plane
#
gcp-controlplane:
	kubectl apply -f ./manifests/workload/gcp/capi-controlplane.yaml
	kubectl get machines --selector cluster.x-k8s.io/control-plane

gcp-cni:
	kubectl --kubeconfig=./gcp-pathtoprod.kubeconfig apply -f ./manifests/workload/cni.yaml

#
# deploy gcp worker nodes
#
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

aws-cluster:
	kubectl apply -f ./manifests/workload/aws/capa-cluster.yaml
	make aws-controlplane
	./wait_for_infra_provisioning.sh "capa-pathtoprod"

	./wait_for_kubeconfig.sh "capa-pathtoprod"
	make aws-kubeconfig

aws-controlplane:
	kubectl apply -f ./manifests/workload/aws/capa-controlplane.yaml
	kubectl get machines --selector cluster.x-k8s.io/control-plane

aws-kubeconfig:
	kubectl --context=$(MANAGER_CLUSTER) get secret capa-pathtoprod-kubeconfig -o json | jq -r .data.value | base64 -D > ./aws-pathtoprod.kubeconfig
	./install_kubeconfig.sh "aws-pathtoprod.kubeconfig"

aws-destroy:
	# -kubectl delete --kubeconfig=./gcp-pathtoprod.kubeconfig --ignore-not-found -f ./manifests/workload/cni.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/aws/capa-worker-nodes.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/aws/capa-controlplane.yaml
	kubectl delete --ignore-not-found -f ./manifests/workload/aws/capa-cluster.yaml