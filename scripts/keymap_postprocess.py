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
import re
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


def _scan_binding_behaviors(zmk_path: Path) -> dict[str, dict[int, set[str]]]:
    """Parse ZMK keymap source and return tags per layer index.

    Returns: {layer_name: {index: {TAGS...}}}
    TAGS examples: {"HRM", "LH", "MT", "TH", "LSP", "RSP"}
    """
    tags: dict[str, dict[int, set[str]]] = {}
    if not zmk_path.is_file():
        return tags
    text = zmk_path.read_text(encoding="utf-8", errors="ignore")
    # Collect blocks with bindings for known layers (plain names)
    plain_layers = ["symbol", "number", "navigation", "window", "bootlaader", "bootloader"]
    for name in plain_layers:
        for m in re.finditer(rf"(?m)^\s*{name}\s*\{{([\s\S]*?)^\s*\}}", text):
            block = m.group(1)
            bm = re.search(r"bindings\s*=\s*<([\s\S]*?)>\s*;", block)
            if not bm:
                continue
            lname, content = name, bm.group(1)
            # Tokenize and tag below
            tokens = content.replace("\n", " ").replace("\t", " ").split()
            arity = {
                "kp": 1,
                "homey_left": 2,
                "homey_right": 2,
                "longer_hold": 2,
                "mt": 2,
                "thumb": 2,
                "lspace": 2,
                "rspace": 2,
                "to": 1,
                "mo": 1,
            }
            b2tag = {
                "homey_left": "HRM",
                "homey_right": "HRM",
                "longer_hold": "LH",
                "mt": "MT",
                "thumb": "TH",
                "lspace": "LSP",
                "rspace": "RSP",
            }
            idx = 0
            i = 0
            layer_tags: dict[int, set[str]] = {}
            while i < len(tokens):
                tok = tokens[i]
                if tok.startswith("&"):
                    binder = tok[1:]
                    tag = b2tag.get(binder)
                    if tag:
                        layer_tags.setdefault(idx, set()).add(tag)
                    i += 1 + arity.get(binder, 1)
                    idx += 1
                else:
                    i += 1
            if layer_tags:
                tags[lname] = layer_tags

    # Collect blocks with names ending in _layer (e.g., default_layer)
    for m in re.finditer(r"(?m)^\s*(\w+_layer)\s*\{([\s\S]*?)^\s*\}", text):
        raw, block = m.group(1), m.group(2)
        bm = re.search(r"bindings\s*=\s*<([\s\S]*?)>\s*;", block)
        if not bm:
            continue
        suffix = "_layer"
        lname = raw[:-len(suffix)] if raw.endswith(suffix) else raw
        content = bm.group(1)
        tokens = content.replace("\n", " ").replace("\t", " ").split()
        arity = {
            "kp": 1,
            "homey_left": 2,
            "homey_right": 2,
            "longer_hold": 2,
            "mt": 2,
            "thumb": 2,
            "lspace": 2,
            "rspace": 2,
            "to": 1,
            "mo": 1,
        }
        skip_tags = {"kp", "macro_tap", "macro_press", "macro_release"}
        idx = 0
        i = 0
        layer_tags: dict[int, set[str]] = {}
        while i < len(tokens):
            tok = tokens[i]
            if tok.startswith("&"):
                binder = tok[1:]
                if binder not in skip_tags:
                    layer_tags.setdefault(idx, set()).add(binder)
                i += 1 + arity.get(binder, 1)
                idx += 1
            else:
                i += 1
        if layer_tags:
            tags[lname] = layer_tags
        # Tokenize
        tokens = content.replace("\n", " ").replace("\t", " ").split()
        arity = {
            "kp": 1,
            "homey_left": 2,
            "homey_right": 2,
            "longer_hold": 2,
            "mt": 2,
            "thumb": 2,
            "lspace": 2,
            "rspace": 2,
            "to": 1,
            "mo": 1,
        }
        skip_tags = {"kp", "macro_tap", "macro_press", "macro_release"}
        idx = 0
        i = 0
        layer_tags: dict[int, set[str]] = {}
        while i < len(tokens):
            tok = tokens[i]
            if tok.startswith("&"):
                binder = tok[1:]
                if binder not in skip_tags:
                    layer_tags.setdefault(idx, set()).add(binder)
                i += 1 + arity.get(binder, 1)
                idx += 1
            else:
                i += 1
        if layer_tags:
            tags[lname] = layer_tags
    return tags


def main(path: Path) -> int:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "layers" not in data:
        print("Not a keymap-drawer YAML file", file=sys.stderr)
        return 2
    layers = data.get("layers", {})
    for lname, items in list(layers.items()):
        layers[lname] = map_value(items)
    # Annotate positions across all layers by scanning ZMK source
    all_tags = _scan_binding_behaviors(Path("config/corne.keymap"))
    for lname, positions in all_tags.items():
        lst = layers.get(lname)
        if not isinstance(lst, list):
            continue
        for i, tset in positions.items():
            if i < len(lst) and isinstance(lst[i], dict):
                # Prefer tagging holds; fall back to tap
                if isinstance(lst[i].get("h"), str) and lst[i]["h"]:
                    label = lst[i]["h"]
                    for tag in sorted(tset):
                        if tag not in label:
                            label += f"·{tag}"
                    lst[i]["h"] = label
                else:
                    t = lst[i].get("t")
                    if isinstance(t, str) and t:
                        for tag in sorted(tset):
                            if tag not in t:
                                t += f"·{tag}"
                        lst[i]["t"] = t
    path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
    print(f"Post-processed: {path}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: keymap_postprocess.py <keymap.yaml>", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1])))
