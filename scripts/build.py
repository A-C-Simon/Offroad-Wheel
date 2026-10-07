#!/usr/bin/env python3
"""Regenerate the committed wheel exports and documentation views."""
import argparse
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "models/rover_wheel_sprung.scad"
OPENSCAD = os.environ.get("OPENSCAD", "openscad")
VIEWS = {
    "front": (0, 0, 0),
    "top": (90, 0, 0),
    "right": (90, 0, 90),
    "isometric": (54.7356, 0, 45),
}


def run(args):
    print("Building", args[args.index("-o") + 1], flush=True)
    subprocess.run([OPENSCAD, "--hardwarnings", *args], cwd=ROOT, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exports", action="store_true", help="rebuild STL files")
    parser.add_argument("--views", action="store_true", help="rebuild four PNG views")
    args = parser.parse_args()
    if not (args.exports or args.views):
        parser.error("select --exports, --views, or both")
    if args.exports:
        (ROOT / "exports").mkdir(exist_ok=True)
        for part, filename in [
            ("assembly", "offroad_wheel.stl"),
            ("rim", "tread_ring.stl"),
            ("cavity", "sealed_air_chambers.stl"),
        ]:
            run(["--export-format", "asciistl", "-D", f'export_part="{part}"',
                 "-o", str(ROOT / "exports" / filename), str(MODEL)])
        legacy = ROOT / "archive/zigzag_wheel/rover_wheel.scad"
        run(["--export-format", "asciistl", "-o", str(legacy.with_suffix(".stl")), str(legacy)])
    if args.views:
        folder = ROOT / "docs/images"
        folder.mkdir(exist_ok=True)
        for name, rotation in VIEWS.items():
            camera = "0,0,0," + ",".join(map(str, rotation)) + ",350"
            # Preview retains assembly colors. STL export evaluates the solid geometry.
            run(["--preview", "--projection=o", "--autocenter", "--viewall",
                 "--colorscheme=Tomorrow", "--imgsize=1400,1100", f"--camera={camera}",
                 "-o", str(folder / f"{name}.png"), str(MODEL)])


if __name__ == "__main__":
    main()
