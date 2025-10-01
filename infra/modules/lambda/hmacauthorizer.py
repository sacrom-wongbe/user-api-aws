import os, json, hmac, hashlib, boto3
from base64 import b64encode, b64decode
from time import time

ssm = boto3.client('ssm')

SECRET = ssm.get_parameter(Name=os.environ['HMAC_SECRET_PARAM'], WithDecryption=True)["Parameter"]["Value"]

def lambda_handler(event, context):
    # Bypass/allow preflight quickly (optional; you can also handle this at API GW)
    http = (event.get("requestContext") or {}).get("http") or {}
    method = (http.get("method") or "").upper()
    if method == "OPTIONS":
        return _allow({"reason": "preflight"})

    # HTTP API v2 shapes
    headers = event.get("headers") or {}
    path    = event.get("rawPath") or ""
    body    = event.get("body") or ""
    if event.get("isBase64Encoded"):
        try:
            body = b64decode(body).decode("utf-8")
        except Exception:
            # If decode fails, treat as empty to keep canonical form simple
            body = ""

    # Required custom headers from Wix backend
    # New unified identity header:
    actor = headers.get("x-actor") or headers.get("X-Actor")
    ts    = headers.get("x-timestamp") or headers.get("X-Timestamp")
    sig   = headers.get("x-signature") or headers.get("X-Signature")

    if not (actor and ts and sig and method and path):
        return _deny("missing_headers")

    # Reject old requests (5 minutes)
    try:
        now_ms = int(time() * 1000)
        # Your Wix code sends Date.now().toString() (epoch ms as string)
        ts_ms = int(float(ts))
        if abs(now_ms - ts_ms) > 5 * 60 * 1000:
            return _deny("stale")
    except Exception:
        return _deny("bad_ts")

    # IMPORTANT: The canonical string MUST match what you sign in Wix:
    # `${ts}:${method}:${path}:${actor}:${body}`
    # NOTE: path should exclude query string on both sides (keep it consistent).
    to_sign = f"{ts}:{method}:{path}:{actor}"

    expected = b64encode(
        hmac.new(
            SECRET.encode("utf-8"),
            to_sign.encode("utf-8"),
            hashlib.sha256
        ).digest()
    ).decode("utf-8")

    print("LAMBDA to_sign:", to_sign)
    print("LAMBDA expected:", expected)
    print("LAMBDA got:", sig)
    # Constant-time compare
    if not hmac.compare_digest(sig, expected):
        return _deny("bad_sig")

    # Pass the actor through to your integrations.
    # Downstream Lambdas read requestContext.authorizer.actor
    return _allow({"actor": actor})

def _allow(ctx: dict):
    return {"isAuthorized": True}

def _deny(reason: str):
    print(f"HMAC DENY: {reason}")  # Log the deny reason for debugging
    return {"isAuthorized": False, "context": {"reason": reason}}