# Create SSM parameter for HMAC secret (SecureString)
resource "aws_ssm_parameter" "hmac_secret" {
  name  = "/lambda/hmac-secret"
  type  = "SecureString"
  value = "CHANGE_THIS_SECRET_IMMEDIATELY_AFTER_CREATION"
  
  description = "HMAC secret for Lambda authorizer - CHANGE IMMEDIATELY"
  
  tags = {
    Environment = "production"
    Purpose     = "lambda-auth"
  }
  
  lifecycle {
    ignore_changes = [value]
  }
}