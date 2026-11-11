#!/usr/bin/env python3
"""Fails when a target imports a module it is not allowed to (LLD §1.3).

The iOS twin of Android's build-logic DependencyRules: features never import other features
or DataLayer, Domain stays pure Swift, and only the app target sees everything.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = ROOT / "Packages" / "LittleStoryKit" / "Sources"
TESTS = ROOT / "Packages" / "LittleStoryKit" / "Tests"

FEATURES = [f"Feature{name}" for name in
            ("Onboarding", "Home", "Discover", "Create", "Reader", "Library", "Settings")]
PROJECT_MODULES = {"Common", "Domain", "DataLayer", "DesignSystem", "CoreUI", "AppFeatures", "TestSupport", *FEATURES}

# Apple / toolchain modules each target may use. Anything not listed here or in ALLOWED is refused.
PURE = {"Foundation", "Observation", "OSLog"}
UI = PURE | {"SwiftUI", "CoreGraphics", "CoreText", "UIKit"}

ALLOWED = {
    "Common": {"modules": set(), "system": PURE},
    "Domain": {"modules": {"Common"}, "system": PURE | {"AsyncAlgorithms"}},
    "DataLayer": {"modules": {"Domain", "Common"}, "system": PURE | {"SwiftData", "AsyncAlgorithms"}},
    "DesignSystem": {"modules": set(), "system": UI},
    "CoreUI": {"modules": {"DesignSystem", "Domain", "Common"}, "system": UI},
    "AppFeatures": {"modules": {*FEATURES, "CoreUI", "DesignSystem", "Domain", "Common"}, "system": UI},
    "TestSupport": {"modules": {"Domain", "Common"}, "system": PURE},
}
for feature in FEATURES:
    ALLOWED[feature] = {"modules": {"CoreUI", "DesignSystem", "Domain", "Common"}, "system": UI | {"AsyncAlgorithms"}}

IMPORT = re.compile(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*import\s+(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?([A-Za-z_][A-Za-z0-9_]*)", re.M)


def check() -> list[str]:
    errors = []
    for target_dir in sorted(p for p in SOURCES.iterdir() if p.is_dir()):
        target = target_dir.name
        rules = ALLOWED.get(target)
        if rules is None:
            errors.append(f"{target}: no dependency rule; add it to Tools/check-dependencies.py and LLD §1.3")
            continue
        for swift in target_dir.rglob("*.swift"):
            for module in IMPORT.findall(swift.read_text(encoding="utf-8")):
                if module == target:
                    continue
                if module in PROJECT_MODULES:
                    if module not in rules["modules"]:
                        errors.append(f"{swift.relative_to(ROOT)}: {target} must not import {module}")
                elif module not in rules["system"]:
                    errors.append(f"{swift.relative_to(ROOT)}: {target} must not import {module}")
    # Tests may import anything from the package, but feature tests must not reach DataLayer.
    for test_dir in sorted(p for p in TESTS.iterdir() if p.is_dir()):
        if test_dir.name.startswith("Feature"):
            for swift in test_dir.rglob("*.swift"):
                if "DataLayer" in IMPORT.findall(swift.read_text(encoding="utf-8")):
                    errors.append(f"{swift.relative_to(ROOT)}: feature tests use fakes, not DataLayer")
    return errors


if __name__ == "__main__":
    problems = check()
    for problem in problems:
        print(f"error: {problem}")
    print(f"check-dependencies: {'FAILED' if problems else 'OK'} ({len(problems)} problem(s))")
    sys.exit(1 if problems else 0)
