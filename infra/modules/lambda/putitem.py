import boto3
import os
import json
from datetime import datetime, timezone
import re
from time import time

# Controlled vocabulary for categories
CATEGORIES = {"education", "fitness", "tools"}

dynamodb = boto3.resource("dynamodb")
items_table = dynamodb.Table(os.environ["ITEMS_TABLE"])

def lambda_handler(event, context):
    # This should eventually check admin auth, for now allow if signed
    actor = event.get("requestContext", {}).get("authorizer", {}).get("actor")
    if not actor or not actor.startswith("user:"):
        return response(403, {"error": "Only users (admins) can create/update items"})
    try:
        item_id = event.get("pathParameters", {}).get("itemId")
        if not item_id or not re.match(r"^item:[a-fA-F0-9\-]{36}$", item_id):
            return response(400, {"error": "Missing or invalid itemId format (must be item:<uuid>)"})
        body = json.loads(event.get("body", "{}"))
        allowed_fields = ["title", "description", "category", "tags", "imgUrl", "popularity"]
        update_fields = {}
        errors = {}
        for k, v in body.items():
            if k not in allowed_fields:
                continue
            if k == "title":
                if not isinstance(v, str) or len(v) > 100:
                    errors[k] = "Must be string, max 100 chars"
                else:
                    update_fields[k] = v
            elif k == "description":
                if not isinstance(v, str) or len(v) > 500:
                    errors[k] = "Must be string, max 500 chars"
                else:
                    update_fields[k] = v
            elif k == "category":
                if v not in CATEGORIES:
                    errors[k] = f"Must be one of: {', '.join(CATEGORIES)}"
                else:
                    update_fields[k] = v
            elif k == "tags":
                if (not isinstance(v, list) or len(v) > 10 or
                    not all(isinstance(tag, str) and tag.islower() and len(tag) <= 30 for tag in v)):
                    errors[k] = "Must be array of lowercase strings, max 10 tags, each ≤ 30 chars"
                else:
                    update_fields[k] = v
            elif k == "imgUrl":
                if not isinstance(v, str) or not re.match(r"^https?://.+", v):
                    errors[k] = "Must be a valid URL"
                else:
                    update_fields[k] = v
            elif k == "popularity":
                if not isinstance(v, int):
                    errors[k] = "Must be integer"
                else:
                    update_fields[k] = v
        if errors:
            return response(400, {"error": "Validation failed", "details": errors})
        if not update_fields:
            return response(400, {"error": "No valid fields to update"})
        # Always update updatedAt
        ts = str(int(time() * 1000))  # epoch milliseconds as string
        update_expr = "SET " + ", ".join(f"#{k} = :{k}" for k in update_fields)
        expr_attr_names = {f"#{k}": k for k in update_fields}
        expr_attr_vals = {f":{k}": v for k, v in update_fields.items()}
        update_expr += ", updatedAt = :u"
        expr_attr_vals[":u"] = ts
        items_table.update_item(
            Key={"itemId": item_id},
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
        "Access-Control-Allow-Origin": "https://www.future-force.org",
        "Access-Control-Allow-Headers": "Content-Type,X-Signature,X-Timestamp,X-Actor",
        "Access-Control-Allow-Methods": "PUT,OPTIONS"
    }
