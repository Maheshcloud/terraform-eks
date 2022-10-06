Add the content of Dockerfile in the Jenkins pipeline job and save it

From command line enter aws configure and enter access_key_id and secret_access_key

Note: Need to install awscli

Connect to the cluster with below command: 
```sh
aws eks --region us-east-1 update-kubeconfig --name eks_cluster_demo
```

export AWS_ACCESS_KEY_ID="value"

export AWS_SECRET_ACCESS_KEY="value"


## Jenkins on Amazon Kubernetes

### Setup Cloud Storage

```sh
# deploy EFS storage driver
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# get VPC ID
aws eks describe-cluster --name eks_cluster_demo --query "cluster.resourcesVpcConfig.vpcId" --output text
# Get CIDR range
aws ec2 describe-vpcs --vpc-ids <vpc-id> --query "Vpcs[].CidrBlock" --output text

# security for our instances to access file storage
aws ec2 create-security-group --description efs-test-sg --group-name efs-sg --vpc-id <VPC_ID>
aws ec2 authorize-security-group-ingress --group-id <sg-xxx>  --protocol tcp --port 2049 --cidr <VPC_CIDR>

# create storage
aws efs create-file-system --creation-token eks-efs

# create mount point 
aws efs create-mount-target --file-system-id <FileSystemId> --subnet-id <SubnetID> --security-group <GroupID>
Note: Make a note of VPC ID, VPC CIDR, GroupID. Also, get the subnet ID from the console

# grab our volume handle to update our PV YAML
aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text
```

Setup a namespace

```sh
kubectl create ns jenkins
```

Setup our storage for Jenkins

```sh
kubectl get storageclass

# create volume
kubectl apply -f jenkins.pv.yml 
kubectl get pv

# create volume claim
kubectl apply -n jenkins -f jenkins.pvc.yml
kubectl -n jenkins get pvc
```

Deploy Jenkins

```sh
# rbac
kubectl apply -n jenkins -f jenkins.rbac.yml 

kubectl apply -n jenkins -f jenkins.deployment.yml

kubectl -n jenkins get pods
```
