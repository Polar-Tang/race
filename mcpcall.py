#!/usr/bin/env python3
"""Minimal streamable-HTTP MCP client for robloxstudio-mcp on localhost:58741.

Usage:
  python3 mcpcall.py list
  python3 mcpcall.py <tool> '<json-args>'
  python3 mcpcall.py execute_luau --luau script.luau
"""
import json
import sys
import urllib.request

URL = "http://localhost:58741/mcp"


def post(payload, session=None):
    req = urllib.request.Request(URL, data=json.dumps(payload).encode(), method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json, text/event-stream")
    if session:
        req.add_header("mcp-session-id", session)
    with urllib.request.urlopen(req, timeout=60) as resp:
        sid = resp.headers.get("mcp-session-id", session)
        body = resp.read().decode()
    if "data:" in body:  # SSE framing
        msgs = [json.loads(l[5:].strip()) for l in body.splitlines() if l.startswith("data:")]
        body = msgs[-1] if msgs else None
    elif body.strip():
        body = json.loads(body)
    else:
        body = None
    return body, sid


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    init, sid = post({
        "jsonrpc": "2.0", "id": 1, "method": "initialize",
        "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                   "clientInfo": {"name": "mcpcall", "version": "1"}},
    })
    post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)

    cmd = sys.argv[1]
    if cmd == "list":
        resp, _ = post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, sid)
        name_filter = sys.argv[2] if len(sys.argv) > 2 else None
        for t in resp["result"]["tools"]:
            if name_filter:
                if t["name"] == name_filter:
                    print(json.dumps(t, indent=2))
            else:
                print(f"- {t['name']}: {t.get('description', '')[:100]}")
        return 0

    if len(sys.argv) >= 4 and sys.argv[2] == "--luau":
        with open(sys.argv[3]) as f:
            args = {"code": f.read()}
    elif len(sys.argv) >= 3:
        args = json.loads(sys.argv[2])
    else:
        args = {}

    resp, _ = post({
        "jsonrpc": "2.0", "id": 2, "method": "tools/call",
        "params": {"name": cmd, "arguments": args},
    }, sid)
    if "error" in resp:
        print("ERROR:", json.dumps(resp["error"], indent=2))
        return 1
    for item in resp["result"].get("content", []):
        print(item.get("text", json.dumps(item)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
