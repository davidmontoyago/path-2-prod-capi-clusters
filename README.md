# path-to-prod-capi-clusters


### Deploy CAPI management cluster

```sh
make pre-reqs

# get CAPI manifests + infra providers (AWS, GCP)
make capi-manifests

# create management cluster
kind create cluster --name=clusterapi
kubectl cluster-info --context kind-clusterapi

# deploy cluster api +infra providers
make manager
```

### Deploy CAPG workload cluster

```sh
export GCP_PROJECT_ID=<>
export GOOGLE_APPLICATION_CREDENTIALS=<>
export GCP_B64ENCODED_CREDENTIALS="$(base64 -i "${GOOGLE_APPLICATION_CREDENTIALS}" | tr -d '\n')"

# gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud auth configure-docker us.gcr.io

# build cluster node image with Packer
cd ../
git clone https://github.com/kubernetes-sigs/image-builder.git
cd image-builder/images/capi
# change packer/config/kubernetes.json to use 1.15.3
make build-gce-default

# verify image was published
gcloud compute images list --project ${GCP_PROJECT_ID} --no-standard-images --filter="family:capi-ubuntu-1804-k8s"

make gcp-cluster

# watch for nodes
kubectl --kubeconfig=./gcp-pathtoprod.kubeconfig get nodes -w
```

### Deploy CAPA workload cluster

```sh

```