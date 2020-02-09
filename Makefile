pre-reqs:
	# kind
	$(GOCMD) get sigs.k8s.io/kind@v0.7.0
	
	# clusterawsadm
	# cd $(HOME)/bin && \
	# 	 curl -LO https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.4.8/clusterawsadm-darwin-amd64 && \
	# 	 chmod 700 ./clusterawsadm-darwin-amd64 && \
	# 	 ln -sf $(HOME)/bin/clusterawsadm-darwin-amd64 $(HOME)/bin/clusterawsadm


#
# get cluster api and bootstrap provider manifests
# 
capi-manifests:
	# cluster api 
	curl -L -o ./manifests/management/cluster-api-components.yaml https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.2.9/cluster-api-components.yaml
	curl -L -o ./manifests/management/bootstrap-components.yaml https://github.com/kubernetes-sigs/cluster-api-bootstrap-provider-kubeadm/releases/download/v0.1.5/bootstrap-components.yaml

# 
# get gcp infra provider manifests
# 
gcp-provider-manifest:
	curl -L -o ./manifests/workload/capg/infrastructure-components.yaml https://github.com/kubernetes-sigs/cluster-api-provider-gcp/releases/download/v0.2.0-alpha.2/infrastructure-components.yaml

# 
# create local management cluster
# 
manager:
	kubectl apply -f manifests/management/cluster-api-components.yaml
	kubectl apply -f manifests/management/bootstrap-components.yaml
	make gcp-provider

# 
# install gcp infra provider
# 
gcp-provider:
	cat ./manifests/management/capg/infrastructure-components.yaml \
  		| envsubst \
  		| kubectl create -f -
