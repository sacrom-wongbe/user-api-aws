# Lambda ARN variables
variable "getme_lambda_arn" {
  description = "ARN of the getMe Lambda function"
  type        = string
}

variable "updateme_lambda_arn" {
  description = "ARN of the updateMe Lambda function"
  type        = string
}

variable "getitem_lambda_arn" {
  description = "ARN of the getItem Lambda function"
  type        = string
}

variable "putitem_lambda_arn" {
  description = "ARN of the putItem Lambda function"
  type        = string
}

variable "postinteraction_lambda_arn" {
  description = "ARN of the postInteraction Lambda function"
  type        = string
}

variable "getinteraction_lambda_arn" {
  description = "ARN of the getInteraction Lambda function"
  type        = string
}

variable "hmac_authorizer_lambda_arn" {
  description = "ARN of the HMAC authorizer Lambda function"
  type        = string
}
