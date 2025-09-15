#!/usr/bin/env python3
"""
Post-process keymap-drawer YAML to prettify custom ZMK behaviors/macros
that the parser leaves as raw strings (e.g., "&alttab").

Usage:
  python3 scripts/keymap_postprocess.py keymap.yaml

It updates the file in-place.
"""
from __future__ import annotations
import sys
from pathlib import Path
import yaml

MAP = {
    "&alttab": "AltTab",
    "&lgui_and_type": "GuiType",
    "&select_line": "SelLn",
    "&select_line_right": "SelLn→",
    "&select_line_left": "←SelLn",
    "&select_word": "SelWrd",
    "&select_word_right": "SelW→",
    "&select_word_left": "←SelW",
    "&winleft": "Win←",
    "&winright": "Win→",
    "&winup": "Win↑",
    "&windown": "Win↓",
    "&winbar": "WinBar",
    "&bootloader": "Boot",
    # Modifiers normalization
    "LGUI": "Gui",
    "RGUI": "Gui",
    "LCTRL": "Ctl",
    "RCTRL": "Ctl",
    "LEFT ALT": "Alt",
    "RIGHT ALT": "AltGr",
    "LALT": "Alt",
    "RALT": "AltGr",
    "LEFT SHIFT": "Sft",
    "RIGHT SHIFT": "Sft",
    "LSHIFT": "Sft",
    "RSHIFT": "Sft",
    "RSHFT": "Sft",
}


def map_value(v):
    if isinstance(v, str):
        return MAP.get(v, v)
    if isinstance(v, dict):
        out = {}
        for k, val in v.items():
            out[k] = map_value(val)
        return out
    if isinstance(v, list):
        return [map_value(x) for x in v]
    return v


def main(path: Path) -> int:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "layers" not in data:
        print("Not a keymap-drawer YAML file", file=sys.stderr)
        return 2
    layers = data.get("layers", {})
    for lname, items in list(layers.items()):
        layers[lname] = map_value(items)
    path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
    print(f"Post-processed: {path}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: keymap_postprocess.py <keymap.yaml>", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1])))
