import boto3
import os
import json

# DynamoDB setup
dynamodb = boto3.resource("dynamodb")
users_table = dynamodb.Table(os.environ["USERS_TABLE"])

def lambda_handler(event, context):
    headers = event.get("headers") or {}
    actor = headers.get("x-actor") or headers.get("X-Actor")
    
    if not actor:
        return {
            "statusCode": 401,
            "headers": cors(),
            "body": json.dumps({"error": "Unauthorized"})
        }
    
    try:
        # Parse actor: "user:abc123" or "guest:def456"
        if actor.startswith("user:"):
            user_id = actor.split(":", 1)[1]
            resp = users_table.get_item(Key={"userId": user_id})
            item = resp.get("Item", {})
            # Only return whitelisted fields if present
            allowed_fields = [
                "userId", "email", "displayName", "realName", "activeness", "role",
                "interestTags", "applicationResponse", "dateOfJoining", "applicationStatus", "updatedAt"
            ]
            filtered_item = {k: item[k] for k in allowed_fields if k in item}
            
            return {
                "statusCode": 200,
                "headers": cors(),
                "body": json.dumps(filtered_item)
            }
        
        elif actor.startswith("guest:"):
            guest_id = actor.split(":", 1)[1]
            # Guests don’t exist in Users table yet → return stub with whitelisted fields
            stub = {
                "guestId": guest_id,
                "type": "guest",
                "email": None,
                "displayName": None,
                "realName": None,
                "activeness": None,
                "role": [],
                "interestTags": [],
                "applicationResponse": None,
                "dateOfJoining": None,
                "applicationStatus": None,
                "updatedAt": None,
                "message": "Guest profile - limited until sign-up"
            }
            
            return {
                "statusCode": 200,
                "headers": cors(),
                "body": json.dumps(stub)
            }
        
        else:
            return {
                "statusCode": 400,
                "headers": cors(),
                "body": json.dumps({"error": "Invalid actor format"})
            }
    
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": cors(),
            "body": json.dumps({"error": str(e)})
        }

def cors():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,X-Signature,X-Timestamp,X-Actor",
        "Access-Control-Allow-Methods": "GET,OPTIONS"
    }
