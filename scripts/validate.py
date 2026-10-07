#!/usr/bin/env python3
"""Check exported STL boundaries and record geometry measurements."""
import hashlib
import json
import math
from collections import Counter, defaultdict
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]


def triangles(path):
    data = path.read_bytes()
    if len(data) >= 84:
        count = struct.unpack_from("<I", data, 80)[0]
        if len(data) == 84 + count * 50:
            for index in range(count):
                values = struct.unpack_from("<12fH", data, 84 + index * 50)
                yield tuple(tuple(values[start:start+3]) for start in (3, 6, 9))
            return
    vertices = []
    for line in data.decode("ascii").splitlines():
        fields = line.split()
        if fields and fields[0] == "vertex":
            vertices.append(tuple(map(float, fields[1:])))
    if not vertices or len(vertices) % 3:
        raise ValueError(f"Invalid STL: {path}")
    for index in range(0, len(vertices), 3):
        yield tuple(vertices[index:index+3])


def measure(path):
    edges = Counter()
    graph = defaultdict(set)
    volume = 0.0
    count = 0
    vertices = set()
    for a, b, c in triangles(path):
        count += 1
        vertices.update((a, b, c))
        volume += (a[0]*(b[1]*c[2]-b[2]*c[1])
                   + a[1]*(b[2]*c[0]-b[0]*c[2])
                   + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6
        for u, v in ((a, b), (b, c), (c, a)):
            edges[tuple(sorted((u, v)))] += 1
            graph[u].add(v)
            graph[v].add(u)
    bad_edges = sum(count != 2 for count in edges.values())
    if bad_edges:
        raise ValueError(f"{path.name}: {bad_edges} edges do not have two incident faces")
    remaining = set(vertices)
    components = 0
    while remaining:
        components += 1
        stack = [remaining.pop()]
        while stack:
            for neighbor in graph[stack.pop()]:
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    stack.append(neighbor)
    return {
        "triangles": count,
        "closed": True,
        "surface_components": components,
        "volume_cm3": round(abs(volume)/1000, 4),
        "bounds_mm": [[min(v[axis] for v in vertices), max(v[axis] for v in vertices)]
                      for axis in range(3)],
        "maximum_radius_mm": round(max(math.hypot(v[0], v[1]) for v in vertices), 4),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def main():
    files = list(sorted((ROOT / "exports").glob("*.stl")))
    files.append(ROOT / "archive/zigzag_wheel/rover_wheel.stl")
    if len(files) != 4 or any(not path.exists() for path in files):
        raise ValueError("Run python3 scripts/build.py --exports first")
    report = {str(path.relative_to(ROOT)): measure(path) for path in files}
    ring = report["exports/tread_ring.stl"]
    air = report["exports/sealed_air_chambers.stl"]
    report["tread_ring_summary"] = {
        "enclosed_air_cm3": air["volume_cm3"],
        "solid_material_cm3": ring["volume_cm3"],
        "hollow_volume_percent": round(100*air["volume_cm3"] /
                                      (air["volume_cm3"]+ring["volume_cm3"]), 2),
    }
    model = ROOT / "models/rover_wheel_sprung.scad"
    report["model_sha256"] = hashlib.sha256(model.read_bytes()).hexdigest()
    target = ROOT / "docs/validation.json"
    target.write_text(json.dumps(report, indent=2)+"\n")
    for path in files:
        item = report[str(path.relative_to(ROOT))]
        print(f"{path.name}: closed, {item['triangles']} triangles, "
              f"{item['volume_cm3']} cm3")
    print(json.dumps(report["tread_ring_summary"]))


if __name__ == "__main__":
    main()
