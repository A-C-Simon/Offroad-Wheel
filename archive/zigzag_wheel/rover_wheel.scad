// Rover wheel reconstructed from the four supplied reference images.
// Dimensions are provisional, in mm; edit them to match your hardware.

/* [Wheel dimensions] */
outside_diameter = 120;
wheel_width = 30;
lug_height = outside_diameter * 8/120;
rim_inner_diameter = outside_diameter * 68/120;
hub_diameter = outside_diameter * 34/120;

/* [Axle] */
axle_hole_diameter = 6;
axle_hole_shape = "round"; // [round,square]

/* [Tread and spokes] */
lug_count = 12;
spoke_thickness = outside_diameter * 2.4/120;
// Change to -1 to mirror the tread and spokes for the opposite side.
handedness = 1; // [-1,1]

/* [Display] */
view_mode = "solid"; // [solid,profile]
$fn = 96;

/* [Hidden] */
outer_r = outside_diameter/2;
root_r = outer_r-lug_height;
inner_r = rim_inner_diameter/2;
hub_r = hub_diameter/2;
pitch = 360/lug_count;

assert(wheel_width > 0 && lug_count >= 3);
assert(outer_r > root_r && root_r > inner_r);
assert(inner_r > hub_r && hub_r > axle_hole_diameter/2);
assert(spoke_thickness > 0 && abs(handedness) == 1);

function polar(r,a) = [r*cos(a),r*sin(a)];

module rounded_path(points, width) {
    for(i=[0:len(points)-2])
        hull() {
            translate(points[i]) circle(d=width,$fn=20);
            translate(points[i+1]) circle(d=width,$fn=20);
        }
}

module wheel_profile() {
    difference() {
        union() {
            // Short leading face and long trailing face on each lug.
            difference() {
                polygon(points=[for(i=[0:lug_count-1])
                    each [polar(root_r,i*pitch),
                          polar(outer_r,i*pitch+0.16*pitch)]]);
                circle(r=inner_r,$fn=24);
            }
            circle(r=hub_r);
            // Four rounded zigzag webs, matching the reference silhouette.
            for(a=[0:90:270]) rotate(a)
                rounded_path([
                    [0,hub_r-outside_diameter*0.6/120],
                    [inner_r*0.52,inner_r*0.70],
                    [-inner_r*0.43,inner_r*0.85],
                    [-inner_r*0.12,inner_r+outside_diameter*0.6/120]
                ],spoke_thickness);
        }
        if(axle_hole_shape == "square")
            square([axle_hole_diameter,axle_hole_diameter],center=true);
        else
            circle(d=axle_hole_diameter);
    }
}

module rover_wheel() {
    scale([handedness,1,1])
        if(view_mode == "profile") wheel_profile();
        else linear_extrude(height=wheel_width,convexity=10)
            wheel_profile();
}

color("#aeb8c2") rover_wheel();
