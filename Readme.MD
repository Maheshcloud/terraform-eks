Add the content of Dockerfile in the Jenkins pipeline job and save it

From command line enter aws configure and enter access_key_id and secret_access_key

If it doesn't work then add below lines in variable.tf file

```sh
variable "ACCESS_KEY" {
 default = "key"
  }

variable "SECRET_KEY" {
  default = "key"
}
```

Note: Need to install awscli

Connect to the cluster with below command: 
```sh
aws eks --region us-east-1 update-kubeconfig --name eks_cluster_demo
```

export AWS_ACCESS_KEY_ID="value"

export AWS_SECRET_ACCESS_KEY="value"



