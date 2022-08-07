
provider "aws" {
  
  region = var.AWS_REGION
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
  
}
data "aws_region" "current" {
}

data "aws_availability_zones" "available" {
}

provider "http" {
}
