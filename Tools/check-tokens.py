#!/usr/bin/env python3
"""Keeps the iOS design tokens in step with the shared design file (LLD §9.1).

  - Every colour in docs/design/design-tokens.json (copied from the Android repo) is in Palette.swift.
  - Colour literals (`lsHex:`) appear only in Palette.swift.
  - Every icon in Icons.xcassets is an LSIcon case and the other way round.
  - Every bundled font has its licence next to it.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOKENS = ROOT / "docs/design/design-tokens.json"
DESIGN_SYSTEM = ROOT / "Packages/LittleStoryKit/Sources/DesignSystem"
PALETTE = DESIGN_SYSTEM / "Palette.swift"
ICONS = DESIGN_SYSTEM / "Resources/Icons.xcassets"
FONTS = DESIGN_SYSTEM / "Resources/Fonts"
LICENSES = DESIGN_SYSTEM / "Resources/Licenses"
HEX = re.compile(r"#([0-9a-fA-F]{6})\b")


def token_colours() -> set[str]:
    colours = set()

    def walk(node):
        if isinstance(node, dict):
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)
        elif isinstance(node, str):
            match = HEX.fullmatch(node.strip())
            if match:
                colours.add(match.group(1).upper())

    walk(json.loads(TOKENS.read_text(encoding="utf-8"))["color"])
    return colours


def check() -> list[str]:
    errors = []
    palette = PALETTE.read_text(encoding="utf-8")
    defined = {value.upper() for value in re.findall(r"lsHex:\s*0x([0-9A-Fa-f]{6})", palette)}
    for colour in sorted(token_colours() - defined):
        errors.append(f"{PALETTE.relative_to(ROOT)}: design colour #{colour} from design-tokens.json is missing")

    for swift in sorted(ROOT.joinpath("Packages/LittleStoryKit/Sources").rglob("*.swift")):
        if swift == PALETTE:
            continue
        for number, line in enumerate(swift.read_text(encoding="utf-8").splitlines(), start=1):
            if re.search(r"lsHex:\s*0x", line):
                errors.append(f"{swift.relative_to(ROOT)}:{number}: colour literal outside Palette.swift")

    cases = set(re.findall(r"^\s*case (\w+)$", (DESIGN_SYSTEM / "LSIcon.swift").read_text(encoding="utf-8"), re.M))
    assets = {path.stem for path in ICONS.glob("*.imageset")}
    for name in sorted(assets - cases):
        errors.append(f"Icons.xcassets/{name}.imageset has no LSIcon case")
    for name in sorted(cases - assets):
        errors.append(f"LSIcon.{name} has no image in Icons.xcassets")

    licences = [path.name.removesuffix("_ofl.txt") for path in LICENSES.glob("*_ofl.txt")]
    for font in sorted(FONTS.glob("*.ttf")):
        # noto_sans_kannada_bold.ttf is covered by noto_sans_kannada_ofl.txt
        if not any(font.stem == name or font.stem.startswith(f"{name}_") for name in licences):
            errors.append(f"{font.relative_to(ROOT)}: no matching *_ofl.txt licence")
    return errors


if __name__ == "__main__":
    problems = check()
    for problem in problems:
        print(f"error: {problem}")
    print(f"check-tokens: {'FAILED' if problems else 'OK'} ({len(problems)} problem(s))")
    sys.exit(1 if problems else 0)
