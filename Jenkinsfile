pipeline{
    agent any
    
    tools {
        terraform 'terraform-ins'
   }
   
   stages{
       stage("git checkout"){
           steps{
               git branch: 'master', url: 'https://github.com/Maheshcloud/terraform-eks.git'
           }
       }
       stage("terraform init"){
           steps{
               sh 'terraform init'
           }
       }
       
       stage("terraform apply"){
           steps{
               sh 'terraform apply --auto-approve'
           }
       }
       
       stage("update kube config"){
           steps{
               sh 'aws eks --region us-east-1 update-kubeconfig --name eks_cluster_demo'
           }
       }
       
       stage("install metrics server"){
           steps{
               sh 'git clone https://github.com/initsixcloud/metric-server.git')
               sh 'kubectl create -f .'
           }
       }
       
     /*  stage("terraform destroy"){
           steps{
              sh 'terraform destroy --auto-approve'
           }
       } */
       
   }
}
