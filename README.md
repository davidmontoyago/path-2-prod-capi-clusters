# path-2-prod-capi-clusters


### Deploy CAPI management cluster

```sh
make pre-reqs

# get CAPI manifests + infra providers (AWS, GCP)
make capi-manifests

# create management cluster
kind create cluster --name=clusterapi
kubectl cluster-info --context kind-clusterapi

# deploy cluster api
make manager
```

### Deploy CAPG workload cluster

```sh
export GCP_PROJECT_ID=<>
export GOOGLE_APPLICATION_CREDENTIALS=<>
export GCP_B64ENCODED_CREDENTIALS="$(base64 -i "${GOOGLE_APPLICATION_CREDENTIALS}" | tr -d '\n')"

# deploy infra provider
make gcp-provider

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
# configure access keys
aws-vault add path2prod.bootstrap

# setup IAM reqs - this will setup a CloudFormation stack with required IAM roles/groups
aws-vault exec --no-session path2prod.bootstrap -- clusterawsadm alpha bootstrap create-stack

export AWS_REGION=<>
export AWS_B64ENCODED_CREDENTIALS=$(aws-vault exec --no-session path2prod.bootstrap -- clusterawsadm alpha bootstrap encode-aws-credentials)

# generate ec2 key pair and place it in parameter store
aws-vault exec path2prod.bootstrap -- aws ssm put-parameter --name "/path-2-prod/cluster-api-provider-aws/ssh-key" \
  --type SecureString \
  --value "$(aws-vault exec path2prod.bootstrap -- aws ec2 create-key-pair --key-name default | jq .KeyMaterial -r)"

# deploy infra provider
make aws-provider

make aws-cluster
```