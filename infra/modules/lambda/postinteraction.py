import boto3
import os
import json
from datetime import datetime, timezone
from time import time

# Strict event types
EVENT_TYPES = {"VIEW": 1, "LIKE": 2, "PURCHASE": 5, "COMMENT": 1, "SHARE": 1}

dynamodb = boto3.resource("dynamodb")
interactions_table = dynamodb.Table(os.environ["INTERACTIONS_TABLE"])
items_table = dynamodb.Table(os.environ["ITEMS_TABLE"])

def lambda_handler(event, context):
    # Get actor from authorizer
    actor = headers.get("x-actor") or headers.get("X-Actor")
    if not actor or not (actor.startswith("user:") or actor.startswith("guest:")):
        return response(400, {"error": "Invalid or missing actorId format"})
    try:
        body = json.loads(event.get("body", "{}"))
        item_id = body.get("itemId")
        event_type = body.get("eventType", "VIEW").upper()
        metadata = body.get("metadata", {})
        weight = body.get("weight", EVENT_TYPES.get(event_type, 1))
        # Validate itemId exists
        if not item_id:
            return response(400, {"error": "Missing itemId"})
        item_resp = items_table.get_item(Key={"itemId": item_id})
        if "Item" not in item_resp:
            return response(400, {"error": "itemId does not exist"})
        # Validate eventType
        if event_type not in EVENT_TYPES:
            return response(400, {"error": f"Invalid eventType: {event_type}"})
        # Validate metadata
        if metadata and not isinstance(metadata, dict):
            return response(400, {"error": "metadata must be a JSON object"})
        # Build keys
        ts = datetime.now(timezone.utc).isoformat()  # epoch milliseconds as string
        sk = f"{ts}#{item_id}"
        # Separate user vs guest
        user_id = None
        guest_id = None
        if actor.startswith("user:"):
            user_id = actor.split(":", 1)[1]
        elif actor.startswith("guest:"):
            guest_id = actor.split(":", 1)[1]
        # Build item
        item = {
            "actorId": actor,
            "SK": sk,
            "itemId": item_id,
            "eventType": event_type,
            "weight": weight,
            "metadata": metadata,
            "ts": ts
        }
        if user_id: item["userId"] = user_id
        if guest_id: item["guestId"] = guest_id
        # Write to DynamoDB
        interactions_table.put_item(Item=item)
        return response(200, {"ok": True, "logged": item})
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
        "Access-Control-Allow-Methods": "POST,OPTIONS"
    }
