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

## Setup a namespace

```sh
kubectl create ns jenkins
```

## Setup our storage for Jenkins

```sh
kubectl get storageclass

# create volume
kubectl apply -f jenkins.pv.yml 

#Note: Update the jenkins.pv.yml with the filesystem ID under volumeHandle
kubectl get pv

# create volume claim
kubectl apply -n jenkins -f jenkins.pvc.yml
kubectl -n jenkins get pvc
```

## Deploy Jenkins

```sh
# rbac
kubectl apply -n jenkins -f jenkins.rbac.yml 

kubectl apply -n jenkins -f jenkins.deployment.yml

kubectl -n jenkins get pods
```
## Expose a service for agents
```sh 
kubectl apply -n jenkins -f jenkins.service.yaml 
```

## Jenkins Initial Setup

```sh 
kubectl -n jenkins exec -it <podname> cat /var/jenkins_home/secrets/initialAdminPassword
kubectl port-forward -n jenkins <podname> 8080
```

## SSH to our node to get Docker user info
```sh 
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
ssh -i ~/.ssh/id_rsa ec2-user@ec2-13-239-41-67.ap-southeast-2.compute.amazonaws.com
id -u docker
cat /etc/group
# Get user ID for docker
# Get group ID for docker
```

## Docker Jenkins Agent
```sh
# you can build it

cd ./jenkins/
docker build . -t mahesh.cloud84/jenkins-slave
```

## Continue Jenkins setup

Install Kubernetes Plugin
Configure Plugin: Values I used are below:

Install Kubernetes Plugin

## Setting up Jenkins Agent

After installing kubernetes-plugin for Jenkins

* Go to Manage Jenkins | Bottom of Page | Cloud | Kubernetes (Add kubenretes cloud)
* Fill out plugin values
    * Name: kubernetes
    * Kubernetes URL: https://kubernetes.default:443
    * Kubernetes Namespace: jenkins
    * Credentials | Add | Jenkins (Choose Kubernetes service account option & Global + Save)
    * Test Connection | Should be successful! If not, check RBAC permissions and fix it!
    * Jenkins URL: http://jenkins
    * Tunnel : jenkins:50000
    * Apply cap only on alive pods : yes!
    * Add Kubernetes Pod Template
       '''sh
         Name: jenkins-slave
         Namespace: jenkins
         Service Account: jenkins
         Labels: jenkins-slave (you will need to use this label on all jobs)
         Containers | Add Template
           Name: jnlp
           Docker Image: aimvector/jenkins-slave
           Command to run :
           Arguments to pass to the command:
           Allocate pseudo-TTY: yes
           Add Volume
              HostPath type
              HostPath: /var/run/docker.sock
              Mount Path: /var/run/docker.sock
    * Timeout in seconds for Jenkins connection: 300

* Save

# Test a build
To run docker commands inside a jenkins agent you will need a custom jenkins agent with docker-in-docker working. Take a look and build the docker file in ./dockerfiles/jenkins-agent Push it to a registry and use it instead of above configured * Docker Image: jenkins/jnlp-slave If you do not use the custom image, the below pipeline will not work because default * Docker Image: jenkins/jnlp-slave public image does not have docker ability.

Add a Jenkins Pipeline
```sh
node('jenkins-slave') {
    
     stage('unit-tests') {
        sh(script: """
            docker run --rm alpine /bin/sh -c "echo hello world"
        """)
    }
}
```

## Try a pipeline
```sh
pipeline {
    agent { 
        kubernetes{
            label 'jenkins-slave'
        }
        
    }
    environment{
        DOCKER_USERNAME = credentials('DOCKER_USERNAME')
        DOCKER_PASSWORD = credentials('DOCKER_PASSWORD')
    }
    stages {
        stage('docker login') {
            steps{
                sh(script: """
                    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                """, returnStdout: true) 
            }
        }

        stage('git clone') {
            steps{
                sh(script: """
                    git clone https://github.com/marcel-dempers/docker-development-youtube-series.git
                """, returnStdout: true) 
            }
        }

        stage('docker build') {
            steps{
                sh script: '''
                #!/bin/bash
                cd $WORKSPACE/docker-development-youtube-series/python
                docker build . --network host -t aimvector/python:${BUILD_NUMBER}
                '''
            }
        }

        stage('docker push') {
            steps{
                sh(script: """
                    docker push aimvector/python:${BUILD_NUMBER}
                """)
            }
        }

        stage('deploy') {
            steps{
                sh script: '''
                #!/bin/bash
                cd $WORKSPACE/docker-development-youtube-series/
                #get kubectl for this demo
                curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
                chmod +x ./kubectl
                ./kubectl apply -f ./kubernetes/configmaps/configmap.yaml
                ./kubectl apply -f ./kubernetes/secrets/secret.yaml
                cat ./kubernetes/deployments/deployment.yaml | sed s/1.0.0/${BUILD_NUMBER}/g | ./kubectl apply -f -
                ./kubectl apply -f ./kubernetes/services/service.yaml
                '''
        }
    }
}
}
```

