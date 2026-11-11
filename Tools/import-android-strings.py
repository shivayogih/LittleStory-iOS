#!/usr/bin/env python3
"""Copies Android string resources into a target's Localizable.xcstrings (LLD §8.2).

Usage: Tools/import-android-strings.py <android-repo> <xcstrings> <android res dir>... [--prefix p_ ...]

- Keys map `home_title_for_child` -> `home.title_for_child` (first underscore becomes a dot).
- Formats map `%1$s` -> `%1$@` and `%1$d` -> `%1$lld`; `<plurals>` become plural variations.
- English is `translated`; every other language is `needs_review` (Draft, needs native review).
- Keys already in the catalog that Android does not have (iOS-only strings) are kept as they are.
Run it again after Android strings change; review the diff before committing.
"""
import argparse
import json
import pathlib
import re
import xml.etree.ElementTree as ET

FORMAT = re.compile(r"%(\d+)\$([sd])")


def ios_key(name: str) -> str:
    head, _, tail = name.partition("_")
    return f"{head}.{tail}" if tail else head


def ios_text(raw: str) -> str:
    text = raw.strip()
    if len(text) >= 2 and text[0] == text[-1] == '"':
        text = text[1:-1]
    text = text.replace("\\'", "'").replace('\\"', '"').replace("\\n", "\n")
    return FORMAT.sub(lambda m: f"%{m.group(1)}${'@' if m.group(2) == 's' else 'lld'}", text)


def read(path: pathlib.Path, prefixes: list[str]) -> dict:
    if not path.exists():
        return {}
    found = {}
    for node in ET.parse(path).getroot():
        name = node.get("name")
        if not name or (prefixes and not name.startswith(tuple(prefixes))) or node.get("translatable") == "false":
            continue
        if node.tag == "string":
            found[name] = ios_text("".join(node.itertext()))
        elif node.tag == "plurals":
            found[name] = {item.get("quantity"): ios_text("".join(item.itertext())) for item in node}
    return found


def unit(value, state: str) -> dict:
    if isinstance(value, dict):
        cases = {q: {"stringUnit": {"state": state, "value": v}} for q, v in value.items()}
        return {"variations": {"plural": cases}}
    return {"stringUnit": {"state": state, "value": value}}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("android_repo", type=pathlib.Path)
    parser.add_argument("catalog", type=pathlib.Path)
    parser.add_argument("res_dirs", nargs="+")
    parser.add_argument("--prefix", action="append", default=[])
    parser.add_argument("--languages", default="kn")
    args = parser.parse_args()

    catalog = json.loads(args.catalog.read_text(encoding="utf-8")) if args.catalog.exists() else {
        "sourceLanguage": "en", "version": "1.0", "strings": {}}
    for res in args.res_dirs:
        base = args.android_repo / res
        english = read(base / "values/strings.xml", args.prefix)
        others = {tag: read(base / f"values-{tag}/strings.xml", args.prefix) for tag in args.languages.split(",")}
        for name, value in english.items():
            localizations = {"en": unit(value, "translated")}
            for tag, strings in others.items():
                if name in strings:
                    localizations[tag] = unit(strings[name], "needs_review")
            catalog["strings"][ios_key(name)] = {
                "comment": f"From Android {res} `{name}`.",
                "extractionState": "manual",
                "localizations": localizations,
            }
    catalog["strings"] = dict(sorted(catalog["strings"].items()))
    args.catalog.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{args.catalog}: {len(catalog['strings'])} keys")


if __name__ == "__main__":
    main()
