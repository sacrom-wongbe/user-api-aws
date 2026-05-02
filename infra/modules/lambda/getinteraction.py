'''
get user's interaction history
'''

import boto3
import os
import json
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource("dynamodb")
interactions_table = dynamodb.Table(os.environ["INTERACTIONS_TABLE"])

STRICT_EVENT_TYPES = {"VIEW", "LIKE", "PURCHASE", "COMMENT", "SHARE"}

def lambda_handler(event, context):
    # Normalize headers to lowercase for consistent access
    raw_headers = event.get("headers", {}) or {}
    headers = {k.lower(): v for k, v in raw_headers.items()}
    # Actor from authorizer
    actor = headers.get("x-actor")
    if not actor or not (actor.startswith("user:") or actor.startswith("guest:")):
        return response(401, {"error": "Unauthorized or invalid actorId format"})

    try:
        path_params = event.get("pathParameters") or {}
        requested_user = path_params.get("userId")
        if requested_user and requested_user != actor:
            return response(403, {"error": "Path userId does not match authenticated actor"})

        query_params = event.get("queryStringParameters") or {}

        # limit
        limit_raw = query_params.get("limit", "20")
        try:
            limit = int(limit_raw)
        except ValueError:
            return response(400, {"error": "limit must be an integer"})
        if limit <= 0 or limit > 100:
            limit = 20

        # eventType filter
        filter_event = query_params.get("eventType")

        # basic query: all interactions for actor
        resp = interactions_table.query(
            KeyConditionExpression=Key("actorId").eq(actor),
            ScanIndexForward=False,  # newest first
            Limit=limit
        )

        items = resp.get("Items", [])

        # optional filter on eventType (strict enum)
        if filter_event:
            filter_event = filter_event.upper()
            if filter_event not in STRICT_EVENT_TYPES:
                return response(400, {"error": f"Invalid eventType: {filter_event}"})
            items = [i for i in items if i.get("eventType") == filter_event]

        # Only return valid interactions
        items = [i for i in items if i.get("eventType") in STRICT_EVENT_TYPES]

        return response(200, {"interactions": items})

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
