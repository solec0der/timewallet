#!/usr/bin/env python3
"""Minimal App Store Connect API client for provisioning fixes.

Usage: asc_api.py <METHOD> <PATH> [JSON_BODY]
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
"""
import json
import os
import sys
import time
import urllib.request

import jwt


def token():
    with open(os.environ["ASC_KEY_PATH"]) as f:
        key = f.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 900,
         "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]},
    )


def main():
    method, path = sys.argv[1], sys.argv[2]
    body = sys.argv[3].encode() if len(sys.argv) > 3 else None
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        data=body, method=method,
        headers={"Authorization": f"Bearer {token()}",
                 "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            print(resp.status)
            print(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(e.code)
        print(e.read().decode())


if __name__ == "__main__":
    main()
