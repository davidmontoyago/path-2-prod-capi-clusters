# path-to-prod-capi-clusters


### Deploy CAPI management cluster

```
export GCP_PROJECT_ID=<>
export GOOGLE_APPLICATION_CREDENTIALS=<>
export GCP_B64ENCODED_CREDENTIALS="$(base64 -i "${GOOGLE_APPLICATION_CREDENTIALS}" | tr -d '\n')"

# gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud auth configure-docker us.gcr.io

make pre-reqs

# get manifests
make capi-manifests

# get manifests
make gcp-provider-manifest

# create management cluster
kind create cluster --name=clusterapi
kubectl cluster-info --context kind-clusterapi

# deploy cluster api +infra providers
make manager
```

### Deploy CAPG workload cluster

```
# build cluster node image with Packer
cd ../
git clone https://github.com/kubernetes-sigs/image-builder.git
cd image-builder/images/capi

# config nat gateway
gcloud compute routers create nat-router \
    --network default \
    --region us-central1
gcloud beta compute routers nats create nat-config \
    --router=nat-router \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges \
    --enable-logging \
    --router-region=us-central1

# verify image was published
gcloud compute images list --project ${GCP_PROJECT_ID} --no-standard-images --filter="family:capi-ubuntu-1804-k8s"

make gcp-cluster

make gcp-controlplane

make gcp-workers
```