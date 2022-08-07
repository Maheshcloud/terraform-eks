
provider "aws" {
  
  region = var.AWS_REGION
  shared_credentials_file = "/home/ubuntu/.aws/credentials"
  profile = "testing"
  
}
data "aws_region" "current" {
}

data "aws_availability_zones" "available" {
}

provider "http" {
}
