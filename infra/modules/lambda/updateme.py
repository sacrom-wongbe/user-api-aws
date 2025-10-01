import boto3
import os
import json
from datetime import datetime
import re
from time import time

dynamodb = boto3.resource("dynamodb")
users_table = dynamodb.Table(os.environ["USERS_TABLE"])

def lambda_handler(event, context):
    # Actor is passed from the Lambda Authorizer (hmacAuthorizer)
    actor = (event.get("headers") or {}).get("x-actor")
    if not actor:
        return response(401, {"error": "Unauthorized"})
    
    # Guests cannot update user profile
    if not actor.startswith("user:"):
        return response(403, {"error": "Guests cannot update user profile"})
    
    user_id = actor.split(":", 1)[1]

    try:
        body = json.loads(event.get("body", "{}"))

        # New whitelist and validation
        allowed_fields = [
            "email", "displayName", "realName", "activeness", "role",
            "interestTags", "applicationResponse", "dateOfJoining", "applicationStatus"
        ]
        update_fields = {}
        errors = {}
        for k, v in body.items():
            if k not in allowed_fields:
                continue
            if k == "email":
                if not isinstance(v, str) or not re.match(r"^[^@]+@[^@]+\.[^@]+$", v):
                    errors[k] = "Must be a valid email address"
                else:
                    update_fields[k] = v
            elif k == "displayName":
                if not isinstance(v, str) or not (1 <= len(v) <= 50) or re.search(r"[\x00-\x1F]", v):
                    errors[k] = "Must be 1-50 chars, no control chars"
                else:
                    update_fields[k] = v
            elif k == "realName":
                if not isinstance(v, str) or not (1 <= len(v) <= 100):
                    errors[k] = "Must be 1-100 chars"
                else:
                    update_fields[k] = v
            elif k == "activeness":
                if v not in ["active", "dormant", "inactive"]:
                    errors[k] = "Must be one of: active, dormant, inactive"
                else:
                    update_fields[k] = v
            elif k == "role":
                if (not isinstance(v, list) or
                    not all(isinstance(role, str) and 1 <= len(role) <= 30 for role in v)):
                    errors[k] = "Must be array of strings, each 1-30 chars"
                else:
                    update_fields[k] = v
            elif k == "interestTags":
                if (not isinstance(v, list) or
                    not all(isinstance(tag, str) and len(tag) <= 30 for tag in v)):
                    errors[k] = "Must be array of strings, each ≤ 30 chars"
                else:
                    update_fields[k] = v
            elif k == "applicationResponse":
                if not isinstance(v, str) or len(v) > 1000:
                    errors[k] = "Must be string, max 1000 chars"
                else:
                    update_fields[k] = v
            elif k == "dateOfJoining":
                # Accept ISO8601 or epoch ms as string
                if not isinstance(v, str) or not (re.match(r"^\d{13}$", v) or re.match(r"^\d{4}-\d{2}-\d{2}", v)):
                    errors[k] = "Must be ISO8601 date string or epoch ms as string"
                else:
                    update_fields[k] = v
            elif k == "applicationStatus":
                if v not in ["rejected", "accepted", "under review"]:
                    errors[k] = "Must be one of: rejected, accepted, under review"
                else:
                    update_fields[k] = v
        if errors:
            return response(400, {"error": "Validation failed", "details": errors})
        if not update_fields:
            return response(400, {"error": "No valid fields to update"})

        # Build UpdateExpression dynamically
        update_expr = "SET " + ", ".join(f"#{k} = :{k}" for k in update_fields)
        expr_attr_names = {f"#{k}": k for k in update_fields}
        expr_attr_vals = {f":{k}": v for k, v in update_fields.items()}

        # Always update updatedAt
        update_expr += ", updatedAt = :u"
        expr_attr_vals[":u"] = str(int(time() * 1000))  # epoch milliseconds as string

        users_table.update_item(
            Key={"userId": user_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_vals
        )

        return response(200, {"ok": True, "updated": list(update_fields.keys())})

    except Exception as e:
        return response(500, {"error": str(e)})

def response(code, obj):
    return {
        "statusCode": code,
        "headers": cors(),
        "body": json.dumps(obj)
    }

def cors():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,X-Signature,X-Timestamp,X-Actor",
        "Access-Control-Allow-Methods": "PUT,OPTIONS"
    }