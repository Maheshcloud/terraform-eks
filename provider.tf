
provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "default"
  region                  = var.AWS_REGION
}
data "aws_region" "current" {
}

data "aws_availability_zones" "available" {
}

provider "http" {
}
