#!/usr/bin/env python3
"""Converts the Android app's vector drawables into the iOS icon asset catalog.

The icons are shared with Android (ADR-iOS-007), so the Android drawables stay the source:
  python3 Tools/convert-icons.py <path-to-LittleStory>/core/designsystem/src/main/res/drawable
writes Packages/LittleStoryKit/Sources/DesignSystem/Resources/Icons.xcassets/<name>.imageset.
Only the subset of VectorDrawable the design uses is supported: <path> elements with stroke or fill.
Run it again whenever an Android icon changes, and commit the result.
"""
import json
import pathlib
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Packages/LittleStoryKit/Sources/DesignSystem/Resources/Icons.xcassets"
ANDROID = "{http://schemas.android.com/apk/res/android}"
INFO = {"author": "xcode", "version": 1}
# VectorDrawable attribute -> SVG attribute
ATTRIBUTES = {
    "pathData": "d",
    "strokeWidth": "stroke-width",
    "strokeLineCap": "stroke-linecap",
    "strokeLineJoin": "stroke-linejoin",
    "fillType": "fill-rule",
}


def colour(value: str) -> str:
    # #AARRGGBB placeholder colours: the icons are template images, tinted by SwiftUI.
    return "#000000" if value.startswith("#") else value


def svg_for(drawable: pathlib.Path) -> tuple[str, bool]:
    vector = ET.parse(drawable).getroot()
    width = vector.get(f"{ANDROID}viewportWidth")
    height = vector.get(f"{ANDROID}viewportHeight")
    mirrored = vector.get(f"{ANDROID}autoMirrored") == "true"
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">']
    for path in vector.iter("path"):
        attributes = {}
        for android, svg in ATTRIBUTES.items():
            value = path.get(f"{ANDROID}{android}")
            if value is not None:
                attributes[svg] = value.lower() if svg == "fill-rule" else value
        stroke = path.get(f"{ANDROID}strokeColor")
        fill = path.get(f"{ANDROID}fillColor")
        attributes["stroke"] = colour(stroke) if stroke else "none"
        attributes["fill"] = colour(fill) if fill else "none"
        rendered = " ".join(f'{key}="{value}"' for key, value in attributes.items())
        parts.append(f"  <path {rendered}/>")
    parts.append("</svg>")
    return "\n".join(parts) + "\n", mirrored


def asset_name(drawable: pathlib.Path) -> str:
    # ic_heart_filled -> heartFilled
    words = drawable.stem.removeprefix("ic_").split("_")
    return words[0] + "".join(word.capitalize() for word in words[1:])


def main(source: pathlib.Path) -> None:
    CATALOG.mkdir(parents=True, exist_ok=True)
    (CATALOG / "Contents.json").write_text(json.dumps({"info": INFO}, indent=2) + "\n", encoding="utf-8")
    for drawable in sorted(source.glob("ic_*.xml")):
        name = asset_name(drawable)
        svg, mirrored = svg_for(drawable)
        imageset = CATALOG / f"{name}.imageset"
        imageset.mkdir(exist_ok=True)
        (imageset / f"{name}.svg").write_text(svg, encoding="utf-8")
        image = {"filename": f"{name}.svg", "idiom": "universal"}
        if mirrored:
            image["language-direction"] = "left-to-right"
        contents = {
            "images": [image],
            "info": INFO,
            "properties": {"preserves-vector-representation": True, "template-rendering-intent": "template"},
        }
        (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
        print(f"{drawable.name} -> {imageset.relative_to(ROOT)}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(pathlib.Path(sys.argv[1]))
