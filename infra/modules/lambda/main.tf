resource "aws_iam_role" "wix-recs-lambda-role" {
  name = "wix-recs-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.wix-recs-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Customer managed policy for DynamoDB access
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda-dynamodb"
  description = "DynamoDB access for Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBReadWriteSpecificTablesAndIndexes"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          "arn:aws:dynamodb:us-west-2:590713443503:table/Interactions",
          "arn:aws:dynamodb:us-west-2:590713443503:table/Users",
          "arn:aws:dynamodb:us-west-2:590713443503:table/Items",
          "arn:aws:dynamodb:us-west-2:590713443503:table/Interactions/index/*",
          "arn:aws:dynamodb:us-west-2:590713443503:table/Users/index/*",
          "arn:aws:dynamodb:us-west-2:590713443503:table/Items/index/*"
        ]
      },
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:us-west-2:590713443503:parameter/lambda/hmac-secret"
        ]
      },
      {
        Sid    = "KMSDecryptForSSM"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.us-west-2.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the customer managed DynamoDB policy
resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.wix-recs-lambda-role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# Create zip file from Python source code
data "archive_file" "getme_zip" {
  type        = "zip"
  source_file = "${path.module}/getme.py"
  output_path = "${path.module}/getme-code.zip"
}

resource "aws_lambda_function" "getMe" {
    function_name = "getMe"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "getme.lambda_handler"
    runtime       = "python3.13"
    
    filename         = data.archive_file.getme_zip.output_path
    source_code_hash = data.archive_file.getme_zip.output_base64sha256
    
    environment {
      variables = {
        USERS_TABLE = "Users"
      }
    }
}

# Create zip file from Python source code
data "archive_file" "updateme_zip" {
  type        = "zip"
  source_file = "${path.module}/updateme.py"
  output_path = "${path.module}/updateme-code.zip"
}

resource "aws_lambda_function" "updateMe" {
    function_name = "updateMe"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "getme.lambda_handler"
    runtime       = "python3.13"
    
    filename         = data.archive_file.updateme_zip.output_path
    source_code_hash = data.archive_file.updateme_zip.output_base64sha256
    
    environment {
      variables = {
        USERS_TABLE = "Users"
      }
    }
}

# Create zip file from Python source code
data "archive_file" "getitem_zip" {
  type        = "zip"
  source_file = "${path.module}/getitem.py"
  output_path = "${path.module}/getitem-code.zip"
}

resource "aws_lambda_function" "getItem" {
    function_name = "getItem"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "getitem.lambda_handler"
    runtime       = "python3.13"

    filename         = data.archive_file.getitem_zip.output_path
    source_code_hash = data.archive_file.getitem_zip.output_base64sha256

    environment {
      variables = {
        ITEMS_TABLE = "Items"
      }
    }
}

# Create zip file from Python source code
data "archive_file" "putitem_zip" {
  type        = "zip"
  source_file = "${path.module}/putitem.py"
  output_path = "${path.module}/putitem-code.zip"
}

resource "aws_lambda_function" "putItem" {
    function_name = "putItem"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "putitem.lambda_handler"
    runtime       = "python3.13"

    filename         = data.archive_file.putitem_zip.output_path
    source_code_hash = data.archive_file.putitem_zip.output_base64sha256

    environment {
      variables = {
        ITEMS_TABLE = "Items"
      }
    }
}

# Create zip file from Python source code
data "archive_file" "postinteraction_zip" {
  type        = "zip"
  source_file = "${path.module}/postinteraction.py"
  output_path = "${path.module}/postinteraction-code.zip"
}

resource "aws_lambda_function" "postInteraction" {
    function_name = "postInteraction"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "postinteraction.lambda_handler"
    runtime       = "python3.13"

    filename         = data.archive_file.postinteraction_zip.output_path
    source_code_hash = data.archive_file.postinteraction_zip.output_base64sha256

    environment {
      variables = {
        ITEMS_TABLE = "Items"
        INTERACTIONS_TABLE = "Interactions"
      }
    }
}

# Create zip file from Python source code
data "archive_file" "getinteraction_zip" {
  type        = "zip"
  source_file = "${path.module}/getinteraction.py"
  output_path = "${path.module}/getinteraction-code.zip"
}

resource "aws_lambda_function" "getInteraction" {
    function_name = "getInteractions"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "getinteraction.lambda_handler"
    runtime       = "python3.13"

    filename         = data.archive_file.getinteraction_zip.output_path
    source_code_hash = data.archive_file.getinteraction_zip.output_base64sha256

    environment {
      variables = {
        INTERACTIONS_TABLE = "Interactions"
      }
    }
}

# Create zip file from Python source code
data "archive_file" "hmacauthorizer_zip" {
  type        = "zip"
  source_file = "${path.module}/hmacauthorizer.py"
  output_path = "${path.module}/hmacauthorizer-code.zip"
}

resource "aws_lambda_function" "hmacAuthorizer" {
    function_name = "hmacAuthorizer"
    role          = aws_iam_role.wix-recs-lambda-role.arn
    handler       = "hmacauthorizer.lambda_handler"
    runtime       = "python3.13"

    filename         = data.archive_file.hmacauthorizer_zip.output_path
    source_code_hash = data.archive_file.hmacauthorizer_zip.output_base64sha256

    environment {
      variables = {
        HMAC_SECRET_PARAM = "/lambda/hmac-secret"
      }
    }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "getme" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getMe.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

resource "aws_lambda_permission" "updateme" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updateMe.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

resource "aws_lambda_permission" "getitem" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getItem.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

resource "aws_lambda_permission" "putitem" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.putItem.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

resource "aws_lambda_permission" "postinteraction" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.postInteraction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

resource "aws_lambda_permission" "getinteraction" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getInteraction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

resource "aws_lambda_permission" "hmac_authorizer" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hmacAuthorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# Remove all CloudWatch Log Group resources - let AWS manage them automatically
resource "aws_cloudwatch_log_group" "getme_logs" {
  name              = "/aws/lambda/getMe"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "updateme_logs" {
  name              = "/aws/lambda/updateMe"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "getitem_logs" {
  name              = "/aws/lambda/getItem"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "putitem_logs" {
  name              = "/aws/lambda/putItem"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "postinteraction_logs" {
  name              = "/aws/lambda/postInteraction"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "getinteraction_logs" {
  name              = "/aws/lambda/getInteractions"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "hmacauthorizer_logs" {
  name              = "/aws/lambda/hmacAuthorizer"
  retention_in_days = 14
}
