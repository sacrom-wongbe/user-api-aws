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
  
  api_gateway_execution_arn = module.api_gateway.execution_arn
}

module "api_gateway" {
  source = "./modules/api_gateway"
  
  # Pass Lambda ARNs to API Gateway
  getme_lambda_arn             = module.lambda.getme_lambda_arn
  updateme_lambda_arn          = module.lambda.updateme_lambda_arn
  getitem_lambda_arn           = module.lambda.getitem_lambda_arn
  putitem_lambda_arn           = module.lambda.putitem_lambda_arn
  postinteraction_lambda_arn   = module.lambda.postinteraction_lambda_arn
  getinteraction_lambda_arn    = module.lambda.getinteraction_lambda_arn
  hmac_authorizer_lambda_arn   = module.lambda.hmac_authorizer_lambda_arn
}

module "ssm_parameter_store" {
  source = "./modules/ssm_parameter_store"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "guardduty" {
  source        = "./modules/guardduty"

  project_name = var.project_name
}

module "cloudtrail" {
  source = "./modules/cloudtrail"

  project_name = var.project_name
}