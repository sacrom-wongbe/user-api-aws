variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "terraform_state_key" {
  description = "S3 key for Terraform state file"
  type        = string
  default     = "infra/terraform.tfstate"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "futureforce-user-api"
}
variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
  default     = "dev" //
}
