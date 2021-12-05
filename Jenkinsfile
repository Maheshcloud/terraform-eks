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
       
       stage("terraform destroy"){
           steps{
              sh 'terraform destroy --auto-approve'
           }
       } 
       
   }
}
