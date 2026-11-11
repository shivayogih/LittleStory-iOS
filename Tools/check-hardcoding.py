#!/usr/bin/env python3
"""Flags hardcoded user-facing text and visual values in Swift sources (CLAUDE.md no-hardcoding policy).

Rules (outside DesignSystem, where tokens are defined):
  - Text("..."), Button("..."), Label("...", ...), .navigationTitle("..."), .accessibilityLabel("...")
    with a literal string: user-facing text belongs in a String Catalog via typed keys.
  - Color(red:...), Color(hex...), UIColor(red:...), Color(.sRGB...): colours are tokens.
  - .font(.system(size: N)): type sizes are tokens.
  - .padding(N), .frame(width: N / height: N), spacing: N, cornerRadius(N) with a number literal.
A line can opt out with a trailing `// hardcoding-ok: <reason>` comment.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCAN = [ROOT / "Packages/LittleStoryKit/Sources", ROOT / "App/Sources"]
TOKEN_HOMES = {"DesignSystem"}

RULES = [
    (re.compile(r'\b(?:Text|Button|Label|Toggle|TextField|SecureField|Link)\(\s*"[^"]'), "literal user-facing text"),
    (re.compile(r'\.(?:navigationTitle|accessibilityLabel|accessibilityHint|accessibilityValue|help)\(\s*"[^"]'), "literal user-facing text"),
    (re.compile(r'\b(?:UI)?Color\(\s*(?:red|hue|white|\.sRGB|hex|displayP3)'), "colour literal"),
    (re.compile(r'\.font\(\s*\.system\(\s*size:'), "font size literal"),
    (re.compile(r'\.padding\(\s*(?:\.\w+\s*,\s*)?\d'), "padding literal"),
    (re.compile(r'\.frame\([^)]*\b(?:width|height|minWidth|maxWidth|minHeight|maxHeight):\s*\d'), "size literal"),
    (re.compile(r'\bspacing:\s*\d'), "spacing literal"),
    (re.compile(r'\.cornerRadius\(\s*\d|RoundedRectangle\(\s*cornerRadius:\s*\d'), "radius literal"),
]


def check() -> list[str]:
    errors = []
    for base in SCAN:
        if not base.exists():
            continue
        for swift in sorted(base.rglob("*.swift")):
            target = swift.relative_to(base).parts[0] if base.name == "Sources" else "App"
            if target in TOKEN_HOMES:
                continue
            in_preview = False
            for number, line in enumerate(swift.read_text(encoding="utf-8").splitlines(), start=1):
                stripped = line.strip()
                if stripped.startswith("#Preview"):
                    in_preview = True
                if in_preview or stripped.startswith("//") or "hardcoding-ok:" in line:
                    continue
                for pattern, what in RULES:
                    if pattern.search(line):
                        errors.append(f"{swift.relative_to(ROOT)}:{number}: {what}: {stripped}")
    return errors


if __name__ == "__main__":
    problems = check()
    for problem in problems:
        print(f"error: {problem}")
    print(f"check-hardcoding: {'FAILED' if problems else 'OK'} ({len(problems)} problem(s))")
    sys.exit(1 if problems else 0)
