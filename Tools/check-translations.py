#!/usr/bin/env python3
"""Checks every Localizable.xcstrings: each key has a non-empty value in every supported language,
format placeholders match English, and lists Kannada text that still needs native review.

Supported languages are read from Common/SupportedLanguage.swift so the registry stays the only list.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "Packages/LittleStoryKit/Sources/Common/SupportedLanguage.swift"
PLACEHOLDER = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|f|\.\d+f|u|lu|llu)")


def languages() -> list[str]:
    tags = re.findall(r'SupportedLanguage\(tag:\s*"([^"]+)"', REGISTRY.read_text(encoding="utf-8"))
    if not tags:
        sys.exit("check-translations: no languages found in SupportedLanguage.swift")
    return tags


def values(entry: dict) -> list[tuple[str, str]]:
    """(variant, value) pairs of one localization, covering plural and device variations."""
    found = []
    if "stringUnit" in entry:
        found.append(("", entry["stringUnit"]))
    for kind, cases in entry.get("variations", {}).items():
        for case, sub in cases.items():
            found += [(f"{kind}.{case}{'.' + v if v else ''}", unit) for v, unit in values(sub)]
    return found


def check() -> tuple[list[str], list[str]]:
    errors, review = [], []
    tags = languages()
    catalogs = sorted(ROOT.glob("Packages/**/Sources/**/*.xcstrings")) + sorted(ROOT.glob("App/**/*.xcstrings"))
    for catalog in catalogs:
        rel = catalog.relative_to(ROOT)
        data = json.loads(catalog.read_text(encoding="utf-8"))
        source = data.get("sourceLanguage", "en")
        for key, item in data.get("strings", {}).items():
            if item.get("shouldTranslate") is False:
                continue
            locs = item.get("localizations", {})
            base = {v: u.get("value", "") for v, u in values(locs.get(source, {}))}
            if not base:
                base = {"": key}
            for tag in tags:
                if tag not in locs:
                    errors.append(f"{rel}: '{key}' has no {tag} translation")
                    continue
                for variant, unit in values(locs[tag]):
                    text = unit.get("value", "")
                    label = f"'{key}'{' [' + variant + ']' if variant else ''} ({tag})"
                    if not text.strip():
                        errors.append(f"{rel}: {label} is empty")
                    english = base.get(variant) or base.get("")
                    if english is not None and sorted(PLACEHOLDER.findall(text)) != sorted(PLACEHOLDER.findall(english)):
                        errors.append(f"{rel}: {label} placeholders differ from {source}")
                    if unit.get("state") == "needs_review":
                        review.append(f"{rel}: {label}")
    return errors, review


if __name__ == "__main__":
    problems, needs_review = check()
    for problem in problems:
        print(f"error: {problem}")
    if needs_review:
        print(f"note: {len(needs_review)} string(s) are drafts that need native review:")
        for item in needs_review:
            print(f"  {item}")
    print(f"check-translations: {'FAILED' if problems else 'OK'} ({len(problems)} problem(s))")
    sys.exit(1 if problems else 0)
