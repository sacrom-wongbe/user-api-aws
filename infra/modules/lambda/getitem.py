'''
Reads a single item from the Items table by itemId.
'''
import boto3
import os
import json
import re

dynamodb = boto3.resource("dynamodb")
items_table = dynamodb.Table(os.environ["ITEMS_TABLE"])

def lambda_handler(event, context):
    # Normalize headers to lowercase for consistent access
    raw_headers = event.get("headers") or {}
    headers = {k.lower(): v for k, v in raw_headers.items()}
    actor = headers.get("x-actor")
    if not actor or not (actor.startswith("user:") or actor.startswith("guest:")):
        return response(400, {"error": "Invalid or missing actor"})
    try:
        path_params = event.get("pathParameters") or {}
        item_id = path_params.get("itemId")
        if not item_id or not re.match(r"^item:[a-fA-F0-9\-]{36}$", item_id):
            return response(400, {"error": "Missing or invalid itemId format (must be item:<uuid>)"})

        result = items_table.get_item(Key={"itemId": item_id})
        item = result.get("Item")
        if not item:
            return response(404, {"error": "Item not found"})

        return response(200, {"ok": True, "item": item})
    except Exception as e:
        return response(500, {"error": str(e)})

def response(code, obj):
    return {
        "statusCode": code,
        "headers": cors(),
        "body": json.dumps(obj, default=str)
    }

def cors():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://www.future-force.org",
        "Access-Control-Allow-Headers": "Content-Type,X-Signature,X-Timestamp,X-Actor",
        "Access-Control-Allow-Methods": "GET,OPTIONS"
    }
