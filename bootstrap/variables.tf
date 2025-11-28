# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "futureforce-user-api"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
  default     = "dev"//prod
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in the format 'owner/repo'"
  default     = "sacrom-wongbe/user-api-aws"
}

variable "github_branch" {
  description = "GitHub branch to allow access"
  type        = string
  default     = "vincent"//main
}

variable "alert_email" {
  description = "Email address for AWS Budget alerts"
  type        = string
}