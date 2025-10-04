# Users table
resource "aws_dynamodb_table" "users" {
  name           = "Users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Name        = "Users"
    Environment = "production"
  }
}

# Items table
resource "aws_dynamodb_table" "items" {
  name           = "Items"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "itemId"

  attribute {
    name = "itemId"
    type = "S"
  }

  tags = {
    Name        = "Items"
    Environment = "production"
  }
}

# Interactions table with GSI
resource "aws_dynamodb_table" "interactions" {
  name           = "Interactions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "actorId"
  range_key      = "ts#itemId"

  attribute {
    name = "actorId"
    type = "S"
  }

  attribute {
    name = "ts#itemId"
    type = "S"
  }

  attribute {
    name = "itemId"
    type = "S"
  }

  attribute {
    name = "eventType#ts#actorId"
    type = "S"
  }

  global_secondary_index {
    name            = "itemId-eventType_ts_actorId-index"
    hash_key        = "itemId"
    range_key       = "eventType#ts#actorId"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Interactions"
    Environment = "production"
  }
}
