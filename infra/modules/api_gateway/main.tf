# API Gateway HTTP API v2
resource "aws_apigatewayv2_api" "main" {
  name          = "wix-recs-api"
  protocol_type = "HTTP"
  description   = "User API for recommendations system"
  
  cors_configuration {
    allow_credentials = true
    allow_headers = [
      "content-type",
      "x-signature",
      "x-timestamp",
      "x-actor"
    ]
    allow_methods = [
      "GET",
      "POST", 
      "PUT",
      "DELETE",
      "OPTIONS"
    ]
    allow_origins = [
      "https://www.future-force.org/blank-8?rc=test-site",
      "https://www.future-force.org",
      "https://editor.wix.com",
      "http://localhost:3000"  # For local development
    ]
    expose_headers = ["x-request-id"]
    max_age       = 86400
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "api-gateway-logs"
  retention_in_days = 14
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      extendedRequestId = "$context.extendedRequestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      path             = "$context.path"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      error            = "$context.error.message"
    })
  }
}

# Lambda integrations
resource "aws_apigatewayv2_integration" "getme" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.getme_lambda_arn
}

resource "aws_apigatewayv2_integration" "updateme" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.updateme_lambda_arn
}

resource "aws_apigatewayv2_integration" "getitem" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.getitem_lambda_arn
}

resource "aws_apigatewayv2_integration" "putitem" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.putitem_lambda_arn
}

resource "aws_apigatewayv2_integration" "postinteraction" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.postinteraction_lambda_arn
}

resource "aws_apigatewayv2_integration" "getinteraction" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.getinteraction_lambda_arn
}

# Lambda Authorizer
resource "aws_apigatewayv2_authorizer" "hmac_authorizer" {
  api_id                           = aws_apigatewayv2_api.main.id
  authorizer_type                  = "REQUEST"
  authorizer_uri                   = var.hmac_authorizer_lambda_arn
  authorizer_payload_format_version = "2.0"
  identity_sources = [
    "$request.header.x-signature",
    "$request.header.X-timestamp",
    "$request.header.X-Actor"
    ]
  name             = "hmac-authorizer"
}

# API Routes with authorization
resource "aws_apigatewayv2_route" "getme" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /me"
  target             = "integrations/${aws_apigatewayv2_integration.getme.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.hmac_authorizer.id
}

resource "aws_apigatewayv2_route" "updateme" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /me"
  target             = "integrations/${aws_apigatewayv2_integration.updateme.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.hmac_authorizer.id
}

resource "aws_apigatewayv2_route" "getitem" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /items/{itemId}"
  target             = "integrations/${aws_apigatewayv2_integration.getitem.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.hmac_authorizer.id
}

resource "aws_apigatewayv2_route" "putitem" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /items/{itemId}"
  target             = "integrations/${aws_apigatewayv2_integration.putitem.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.hmac_authorizer.id
}

resource "aws_apigatewayv2_route" "postinteraction" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /interactions"
  target             = "integrations/${aws_apigatewayv2_integration.postinteraction.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.hmac_authorizer.id
}

resource "aws_apigatewayv2_route" "getinteraction" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /interactions/{userId}"
  target             = "integrations/${aws_apigatewayv2_integration.getinteraction.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.hmac_authorizer.id
}