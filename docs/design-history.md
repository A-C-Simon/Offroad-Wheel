# Design history

The design commits were reconstructed from saved OpenSCAD snapshots and recorded parameter changes. Their dates reflect the repository import, not the original modeling sessions. Each commit isolates one design idea or correction.

| Commit | Change |
| --- | --- |
| [ea7eeb2](https://github.com/A-C-Simon/Offroad-Wheel/commit/ea7eeb2) | Model the original wheel with zigzag spokes and sawtooth tread |
| [3eb872c](https://github.com/A-C-Simon/Offroad-Wheel/commit/3eb872c) | Explore a 200 mm diameter and 150 mm wheel width |
| [10ddeb2](https://github.com/A-C-Simon/Offroad-Wheel/commit/10ddeb2) | Restore the 120 mm diameter and 30 mm width |
| [f410449](https://github.com/A-C-Simon/Offroad-Wheel/commit/f410449) | Replace zigzag spokes with six spring and pivot assemblies |
| [3e28506](https://github.com/A-C-Simon/Offroad-Wheel/commit/3e28506) | Close the outer tread surface and remove the display cutaway |
| [7ef4d87](https://github.com/A-C-Simon/Offroad-Wheel/commit/7ef4d87) | Add small sealed buoyancy chambers with thick walls and radial ribs |
| [e3a0841](https://github.com/A-C-Simon/Offroad-Wheel/commit/e3a0841) | Widen the buoyancy ring and deepen the terrain paddles |
| [bcee731](https://github.com/A-C-Simon/Offroad-Wheel/commit/bcee731) | Shrink the hub and lengthen the spring assemblies |
| [47108f6](https://github.com/A-C-Simon/Offroad-Wheel/commit/47108f6) | Use twelve shallow swept teeth around the circular tread |
| [051f3ae](https://github.com/A-C-Simon/Offroad-Wheel/commit/051f3ae) | Increase the shallow tooth depth to eight millimeters |
| [c18e9ac](https://github.com/A-C-Simon/Offroad-Wheel/commit/c18e9ac) | Deepen the inward tooth roots while retaining the tip envelope |
| [8d5671d](https://github.com/A-C-Simon/Offroad-Wheel/commit/8d5671d) | Raise the long flanks and tuck short flanks beneath fixed peaks |
| [5151583](https://github.com/A-C-Simon/Offroad-Wheel/commit/5151583) | Add smaller counter-facing teeth for reverse travel |
| [28338fc](https://github.com/A-C-Simon/Offroad-Wheel/commit/28338fc) | Shape the forward and reverse contact faces as circular arcs |
| [498bf4c](https://github.com/A-C-Simon/Offroad-Wheel/commit/498bf4c) | Round the inward valleys and evaluate rounded tooth tips |
| [b72284a](https://github.com/A-C-Simon/Offroad-Wheel/commit/b72284a) | Restore sharp paddle peaks and retain only inward valley fillets |
| [1a6c4aa](https://github.com/A-C-Simon/Offroad-Wheel/commit/1a6c4aa) | Extend the forward teeth four millimeters along their existing arcs |

The original zigzag wheel is retained in `archive/zigzag_wheel`. The spring-wheel history uses `models/rover_wheel_sprung.scad` throughout, so any stage can be inspected with `git show <commit>:models/rover_wheel_sprung.scad`.

The final design keeps the extended forward arcs, smaller opposing teeth, sharp peaks and rounded inward valleys. The enclosed tread chambers, smaller hub and longer spring assemblies remain part of the model.
