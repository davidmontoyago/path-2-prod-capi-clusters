# path-to-prod-capi-clusters


```
export GCP_PROJECT_ID=<>
export GOOGLE_APPLICATION_CREDENTIALS=<>
export GCP_B64ENCODED_CREDENTIALS="$(base64 -i "${GOOGLE_APPLICATION_CREDENTIALS}" | tr -d '\n')"

# jk! not needed
# gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS

make pre-reqs

# get manifests
make capi-manifests

# get manifests
make gcp-provider-manifest

# create management cluster
kind create cluster --name=clusterapi
kubectl cluster-info --context kind-clusterapi

# deploy cluster api
make manager
 
# deploy gcp infra provider
gcloud auth configure-docker us.gcr.io
make gcp-provider
```