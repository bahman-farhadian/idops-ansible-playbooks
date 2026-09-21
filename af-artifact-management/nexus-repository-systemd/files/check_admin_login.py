#!/usr/bin/env python3
"""Check that Nexus web UI sign-in accepts the admin user."""
import argparse
import base64
import json
import sys
import urllib.error
import urllib.parse
import urllib.request


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--user", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()
    form = urllib.parse.urlencode(
        {
            "username": base64.b64encode(args.user.encode()).decode(),
            "password": base64.b64encode(args.password.encode()).decode(),
        }
    ).encode()
    request = urllib.request.Request(
        args.url.rstrip("/") + "/service/rapture/session",
        data=form,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "X-Nexus-UI": "true",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            if response.status in (200, 204):
                print("web UI sign-in as admin works")
                return 0
            print(f"web UI sign-in HTTP {response.status}", file=sys.stderr)
            return 1
    except urllib.error.HTTPError as exc:
        print(f"web UI sign-in HTTP {exc.code}", file=sys.stderr)
        return 1
    except (TimeoutError, urllib.error.URLError) as exc:
        print(f"web UI sign-in failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
