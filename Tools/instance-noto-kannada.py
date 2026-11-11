#!/usr/bin/env python3
"""Writes static weights of Noto Sans Kannada for the iOS bundle.

CoreText applies neither a `wght` variation nor the named instances of the variable
Noto Sans Kannada file (DM Sans and Manrope work), so iOS ships static instances instead.
Requires fontTools (pip install fonttools):
  python3 Tools/instance-noto-kannada.py <path-to-LittleStory>/core/designsystem/src/main/res/font/noto_sans_kannada.ttf
"""
import pathlib
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

OUT = pathlib.Path(__file__).resolve().parent.parent / "Packages/LittleStoryKit/Sources/DesignSystem/Resources/Fonts"
WEIGHTS = {400: "regular", 500: "medium", 600: "semibold", 700: "bold", 800: "extrabold"}


def main(source: pathlib.Path) -> None:
    for weight, name in WEIGHTS.items():
        font = instancer.instantiateVariableFont(TTFont(source), {"wght": weight, "wdth": 100}, updateFontNames=True)
        target = OUT / f"noto_sans_kannada_{name}.ttf"
        font.save(target)
        print(f"{target.name}: {font['name'].getDebugName(6)}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(pathlib.Path(sys.argv[1]))
