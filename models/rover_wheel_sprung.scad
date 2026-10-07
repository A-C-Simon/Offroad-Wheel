// Concept assembly from the updated sketch. Units: mm.
// Spring, bearing, pin, and clearances are illustrative, not hardware specifications.
// Springs show compliance; this model does not simulate forces or damping.

/* [Wheel] */
outside_diameter = 120;
wheel_width = 30;
hub_diameter = 34;
axle_hole_diameter = 6;
lug_count = 8;
spoke_count = 6;
lug_height = 8;
rim_inner_diameter = 88;

/* [Sealed tread cavity] */
// Thick skins, narrow chambers, solid teeth, and bridges between chambers.
rim_wall = 3;
cavity_radial_width = 2;
cavity_rib_width = 2;
cavity_rib_count = 8;

/* [Springs] */
spring_turns = 7;
spring_coil_diameter = 6;
spring_wire_diameter = 0.8;

/* [Display] */
show_springs = true;
$fn = 64;

/* [Hidden] */
export_part = "assembly";
outer_r = outside_diameter/2;
root_r = outer_r-lug_height;
inner_r = rim_inner_diameter/2;
hub_r = hub_diameter/2;
zmid = wheel_width/2;
spring_start = hub_r+9;
spring_end = inner_r-4;
pivot_r = inner_r-1;
spring_length = spring_end-spring_start;

assert(root_r > inner_r+rim_wall+cavity_radial_width);
assert(wheel_width > 2*rim_wall);
assert(rim_wall > 0 && cavity_radial_width > 0 && cavity_rib_width > 0);
assert(spring_length > spring_wire_diameter*spring_turns);
assert(wheel_width > 16 && hub_r > axle_hole_diameter/2);

function polar(r,a) = [r*cos(a),r*sin(a)];
module tread_outline() {
    polygon([for(i=[0:lug_count-1]) each
        [polar(root_r,i*360/lug_count),
         polar(outer_r,(i+0.16)*360/lug_count)]]);
}

// The cavity is entirely enclosed. Radial bridges create separate chambers.
module tread_cavity() {
    translate([0,0,rim_wall]) linear_extrude(wheel_width-2*rim_wall)
        difference() {
            difference() {
                intersection() {
                    circle(r=inner_r+rim_wall+cavity_radial_width);
                    offset(delta=-rim_wall) tread_outline();
                }
                circle(r=inner_r+rim_wall);
            }
            for(a=[0:360/cavity_rib_count:359]) rotate(a)
                translate([inner_r+rim_wall-1,-cavity_rib_width/2])
                    square([cavity_radial_width+2,cavity_rib_width]);
        }
}

module solid_rim() {
    linear_extrude(wheel_width) difference() {
        tread_outline();
        circle(r=inner_r);
    }
}

module sealed_rim() {
    difference() {
        solid_rim();
        tread_cavity();
    }
}

// Closed swept tube, with its helix axis along X.
module coil(length, radius, wire, turns) {
    segments = turns*20;
    sides = 8;
    advance = length/(turns*2*PI);
    denom = sqrt(radius*radius+advance*advance);
    vertices = [for(i=[0:segments],j=[0:sides-1]) let(
        a=i/segments*turns*360,
        b=j/sides*360,
        u=wire/2*cos(b), v=wire/2*sin(b))
        [length*i/segments+v*radius/denom,
         radius*cos(a)+u*cos(a)+v*advance*sin(a)/denom,
         radius*sin(a)+u*sin(a)-v*advance*cos(a)/denom]];
    faces = concat(
        [for(i=[0:segments-1],j=[0:sides-1]) each [
            [i*sides+j,(i+1)*sides+j,(i+1)*sides+(j+1)%sides],
            [i*sides+j,(i+1)*sides+(j+1)%sides,i*sides+(j+1)%sides]]],
        [[for(j=[0:sides-1]) j]],
        [[for(j=[sides-1:-1:0]) segments*sides+j]]);
    polyhedron(vertices,faces,convexity=10);
}

module radial_cylinder(start,length,radius) {
    translate([start,0,zmid]) rotate([0,90,0])
        cylinder(h=length,r=radius);
}

module spring_spoke() {
    // Hub-side sleeve and exposed piston rod.
    color("#5f7486") translate([hub_r-1,-2.5,zmid-4])
        cube([10,5,8]);
    color("#b8c3cc") radial_cylinder(hub_r+7,inner_r-hub_r-9,1.1);
    // End seats for the spring.
    color("#93a8b9") {
        radial_cylinder(spring_start-0.6,1.2,spring_coil_diameter/2+0.7);
        radial_cylinder(spring_end-0.6,1.2,spring_coil_diameter/2+0.7);
    }
    if(show_springs) color("#e3b54b")
        translate([spring_start,0,zmid])
            coil(spring_length,spring_coil_diameter/2,
                 spring_wire_diameter,spring_turns);
    // Rim-side hinge eye, with its pin axis along the wheel axis.
    color("#718899") difference() {
        union() {
            translate([spring_end-1,-2,zmid-2])
                cube([pivot_r-spring_end+1,4,4]);
            translate([pivot_r,0,zmid-2]) cylinder(h=4,r=2.6);
        }
        translate([pivot_r,0,zmid-3]) cylinder(h=6,r=1.25);
    }
    // Two bracket ears attach the pivot to the inside of the rim.
    color("#aeb8c2") for(z=[zmid-5,zmid+2.4])
        difference() {
            hull() {
                translate([pivot_r,0,z]) cylinder(h=2.6,r=3);
                translate([inner_r+0.5,-3,z]) cube([1,6,2.6]);
            }
            translate([pivot_r,0,z-0.1]) cylinder(h=2.8,r=1.25);
        }
    color("#354754") translate([pivot_r,0,zmid-5.6]) {
        cylinder(h=11.2,r=1.1);
        cylinder(h=0.8,r=1.9);
        translate([0,0,10.4]) cylinder(h=0.8,r=1.9);
    }
}

module wheel_assembly() {
    color("#aeb8c2") sealed_rim();
    color("#5f7486") difference() {
        cylinder(h=wheel_width,r=hub_r);
        translate([0,0,-0.1]) cylinder(h=wheel_width+0.2,d=axle_hole_diameter);
    }
    for(i=[0:spoke_count-1]) rotate([0,0,30+i*360/spoke_count]) spring_spoke();
}

// Alternate exports enable checking the enclosed void and its volume.
if(export_part == "rim") sealed_rim();
else if(export_part == "cavity") tread_cavity();
else if(export_part == "solid_rim") solid_rim();
else wheel_assembly();
