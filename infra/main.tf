provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.66.0"
    }
  }

  backend "s3" {
    bucket         = "futureforce-user-api-terraform-state-590713443503"
    key            = "infra/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    use_lockfile   = true         # Replace deprecated dynamodb_table parameter
  }
}

module "lambda" {
    source = "./modules/lambda"

}

module "ssm_parameter_store" {
  source = "./modules/ssm_parameter_store"
}