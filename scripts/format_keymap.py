#!/usr/bin/env python3
"""
Lightweight formatter for ZMK/Zephyr devicetree-style keymap files.

What it does (conservative):
- 4-space indentation based on curly braces { }
- Keeps #include lines unindented
- Trims trailing whitespace
- Collapses multiple blank lines to a single blank line
- Preserves content and ordering (no semantic changes)

Usage:
  python3 scripts/format_keymap.py config/corne.keymap
"""

import sys
from pathlib import Path


def format_lines(lines: list[str]) -> list[str]:
    out: list[str] = []
    indent = 0
    INDENT_WIDTH = 4
    last_was_blank = False

    for raw in lines:
        # Normalize line endings and trim trailing whitespace
        raw = raw.rstrip("\r\n")
        s = raw.rstrip()
        # Tabs → spaces (preserve alignment conservatively)
        s = s.replace("\t", " " * INDENT_WIDTH)

        # Detect blank
        if s.strip() == "":
            if not last_was_blank and out:
                out.append("\n")
                last_was_blank = True
            continue
        last_was_blank = False

        stripped = s.lstrip()

        # Compute pre-line indent
        pre_indent = indent

        # Dedent lines that begin with closing brace
        if stripped.startswith("};") or stripped.startswith("}"):
            indent = max(0, indent - 1)

        # Keep includes at column 0 for readability
        if stripped.startswith("#include"):
            indented_line = stripped
        else:
            indented_line = (" " * (indent * INDENT_WIDTH)) + stripped

        out.append(indented_line + "\n")

        # Update indent based on brace balance for final indent after this line
        open_count = s.count("{")
        close_count = s.count("}")
        indent = max(0, pre_indent + open_count - close_count)

    # Ensure file ends with a single newline
    if not out or out[-1] != "\n":
        if out and not out[-1].endswith("\n"):
            out[-1] = out[-1] + "\n"
        elif not out:
            out = ["\n"]
    return out


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: format_keymap.py <path-to-keymap>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"Not a file: {path}", file=sys.stderr)
        return 2

    original = path.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    formatted = format_lines(original)

    # Only write if changed
    if original != formatted:
        path.write_text("".join(formatted), encoding="utf-8")
        print(f"Formatted: {path}")
    else:
        print(f"No changes needed: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

