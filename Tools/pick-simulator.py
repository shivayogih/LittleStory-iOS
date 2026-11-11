#!/usr/bin/env python3
"""Prints an xcodebuild destination id for the newest available iPhone or iPad simulator.

Usage: pick-simulator.py iphone|ipad. Picking by kind instead of a hardcoded device name keeps CI
working when runner images rename or add simulators.
"""
import json
import subprocess
import sys

kind = sys.argv[1].lower() if len(sys.argv) > 1 else "iphone"
prefix = {"iphone": "iPhone", "ipad": "iPad"}[kind]
listing = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))


def version(runtime: str) -> tuple[int, ...]:
    tail = runtime.rsplit("iOS-", 1)[-1]
    return tuple(int(part) for part in tail.split("-") if part.isdigit())


candidates = [
    (version(runtime), device["name"], device["udid"])
    for runtime, devices in listing["devices"].items() if "iOS" in runtime
    for device in devices if device["name"].startswith(prefix)
]
if not candidates:
    sys.exit(f"no available {prefix} simulator")
# Newest runtime first; prefer a mainstream model (iPhone NN / iPad Air) over Pro Max / mini variants.
preferred = {"iphone": ("Pro Max", "Plus", "mini", "SE", "16e", "17e"), "ipad": ("mini", "Pro (12.9", "13-inch")}[kind]
candidates.sort(key=lambda c: (c[0], not any(word in c[1] for word in preferred)), reverse=True)
best = candidates[0]
print(f"picked {best[1]} (iOS {'.'.join(map(str, best[0]))})", file=sys.stderr)
print(f"id={best[2]}")
