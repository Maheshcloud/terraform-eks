
provider "aws" {
  
  region = "us-east-1"
  access_key = "AKIAZ7TU5BBJT5EMEWNT"
  secret_key = "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"
  
}
data "aws_region" "current" {
}

data "aws_availability_zones" "available" {
}

provider "http" {
}
