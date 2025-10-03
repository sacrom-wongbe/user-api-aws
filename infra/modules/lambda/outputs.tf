# Lambda ARN outputs
output "getme_lambda_arn" {
  description = "ARN of the getMe Lambda function"
  value       = aws_lambda_function.getMe.invoke_arn
}

output "updateme_lambda_arn" {
  description = "ARN of the updateMe Lambda function"
  value       = aws_lambda_function.updateMe.invoke_arn
}

output "getitem_lambda_arn" {
  description = "ARN of the getItem Lambda function"
  value       = aws_lambda_function.getItem.invoke_arn
}

output "putitem_lambda_arn" {
  description = "ARN of the putItem Lambda function"
  value       = aws_lambda_function.putItem.invoke_arn
}

output "postinteraction_lambda_arn" {
  description = "ARN of the postInteraction Lambda function"
  value       = aws_lambda_function.postInteraction.invoke_arn
}

output "getinteraction_lambda_arn" {
  description = "ARN of the getInteraction Lambda function"
  value       = aws_lambda_function.getInteraction.invoke_arn
}

output "hmac_authorizer_lambda_arn" {
  description = "ARN of the HMAC authorizer Lambda function"
  value       = aws_lambda_function.hmacAuthorizer.invoke_arn
}

# Lambda name outputs
output "getme_lambda_name" {
  description = "Name of the getMe Lambda function"
  value       = aws_lambda_function.getMe.function_name
}

output "updateme_lambda_name" {
  description = "Name of the updateMe Lambda function"
  value       = aws_lambda_function.updateMe.function_name
}

output "getitem_lambda_name" {
  description = "Name of the getItem Lambda function"
  value       = aws_lambda_function.getItem.function_name
}

output "putitem_lambda_name" {
  description = "Name of the putItem Lambda function"
  value       = aws_lambda_function.putItem.function_name
}

output "postinteraction_lambda_name" {
  description = "Name of the postInteraction Lambda function"
  value       = aws_lambda_function.postInteraction.function_name
}

output "getinteraction_lambda_name" {
  description = "Name of the getInteraction Lambda function"
  value       = aws_lambda_function.getInteraction.function_name
}

output "hmac_authorizer_lambda_name" {
  description = "Name of the HMAC authorizer Lambda function"
  value       = aws_lambda_function.hmacAuthorizer.function_name
}
