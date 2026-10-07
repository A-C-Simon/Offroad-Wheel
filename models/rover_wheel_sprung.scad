// All-terrain paddle-wheel concept based on the updated sketch. Units: mm.
// Sharp forward/reverse peaks, circular contact arcs, and rounded inward valleys.
// Spring, bearing, pin, and clearances are illustrative, not hardware specifications.
// Springs show compliance; this model does not simulate forces or damping.

/* [Wheel] */
outside_diameter = 120;
wheel_width = 30;
hub_diameter = 24;
axle_hole_diameter = 6;
lug_count = 12;
spoke_count = 6;
lug_height = 11;
// Position of the paddle tip within each pitch; larger values sweep it back.
lug_sweep = 0.82;
// Short flank leans inward underneath the fixed tip. Angle in degrees.
short_flank_backstep = 2;
rim_inner_diameter = 64;

/* [Reverse teeth] */
reverse_teeth = true;
reverse_tooth_height = 3;
// Location along each main tooth's long flank.
reverse_tooth_position = 0.52;

/* [Tooth fillets] */
// Larger inward fillets remove the narrow dirt-catching valleys.
valley_fillet_radius = 2;

/* [Sealed tread cavity] */
// Thick skins, narrow chambers, solid teeth, and bridges between chambers.
rim_wall = 3;
cavity_radial_width = 6;
cavity_rib_width = 2;
cavity_rib_count = 8;

/* [Springs] */
spring_turns = 5;
spring_coil_diameter = 5;
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
sleeve_length = 6;
spring_start = hub_r+sleeve_length;
spring_end = inner_r-4;
pivot_r = inner_r-1;
spring_length = spring_end-spring_start;

assert(root_r > inner_r+rim_wall+cavity_radial_width);
assert(wheel_width > 2*rim_wall);
assert(rim_wall > 0 && cavity_radial_width > 0 && cavity_rib_width > 0);
assert(spring_length > spring_wire_diameter*spring_turns);
assert(wheel_width > 16 && hub_r > axle_hole_diameter/2);
assert(lug_sweep >= 0.5 && lug_sweep <= 0.85);
assert(reverse_tooth_height > 0);
assert(valley_fillet_radius > 0);
assert(reverse_tooth_position >= 0.4 && reverse_tooth_position <= 0.6);

function polar(r,a) = [r*cos(a),r*sin(a)];
function bezier(p0,p1,p2,p3,t) =
    (1-t)*(1-t)*(1-t)*p0 + 3*(1-t)*(1-t)*t*p1
    + 3*(1-t)*t*t*p2 + t*t*t*p3;

// Sharp peaks define the envelope; only inward valleys receive fillets.
function tooth_tip(i) = polar(outer_r,(i+lug_sweep)*360/lug_count);
// Circular contact arc, tangent to the wheel circumference at the main tip.
function arc_to_tip(start,tip,t) = let(
    tip_r=norm(tip), unit=tip/tip_r,
    center=unit*((tip_r*tip_r-start*start)/(2*(tip_r-start*unit))),
    radius=norm(tip-center),
    start_a=atan2(start[1]-center[1],start[0]-center[0]),
    end_a=atan2(tip[1]-center[1],tip[0]-center[0]),
    sweep=(end_a-start_a+360)%360)
    center+polar(radius,start_a+sweep*t);
function main_flank(i,t) = let(a=(i+lug_sweep)*360/lug_count)
    arc_to_tip(polar(root_r,a-short_flank_backstep),tooth_tip(i+1),t);

// True circular arc through three points for the small reverse tooth's crown.
function arc_through(start,middle,end,t) = let(
    u=middle-start, v=end-start,
    du=middle*middle-start*start, dv=end*end-start*start,
    det=2*(u[0]*v[1]-u[1]*v[0]),
    center=[(du*v[1]-dv*u[1])/det,(u[0]*dv-v[0]*du)/det],
    radius=norm(start-center),
    a0=atan2(start[1]-center[1],start[0]-center[0]),
    a1=atan2(end[1]-center[1],end[0]-center[0]),
    sweep=(a1-a0+360)%360)
    center+polar(radius,a0+sweep*t);

function point_angle(p) = atan2(p[1],p[0]);
function paired_tooth_points(i) = let(
    t=reverse_tooth_position,
    base=main_flank(i,t),
    base_a=point_angle(base),
    base_r=norm(base),
    reverse_r=min(outer_r-0.8,base_r+reverse_tooth_height),
    reverse_a=base_a-2,
    reverse_tip=polar(reverse_r,reverse_a),
    // Opposite lean: this root lies ahead of the reverse tip, rather than behind.
    reverse_foot=polar(base_r-1,base_a+1.6),
    entry=main_flank(i,t-0.22),
    exit=main_flank(i,t+0.34),
    return_sweep=(point_angle(exit)-reverse_a+360)%360,
    crown=polar(min(outer_r-0.15,max(reverse_r,norm(exit))+0.15),
                reverse_a+return_sweep/2))
    concat(
        [tooth_tip(i),main_flank(i,0)],
        [for(j=[1:6]) main_flank(i,(t-0.22)*j/6)],
        // Recessed inward curve leading into the short counter-facing flank.
        [for(j=[1:7]) bezier(entry,polar(base_r-2,base_a-5),
            polar(base_r-1.4,base_a+0.7),reverse_foot,j/7)],
        [reverse_tip],
        // Long return follows the circumference and curves gently inward.
        [for(j=[1:24]) arc_through(reverse_tip,crown,exit,j/24)],
        [for(j=[1:4]) main_flank(i,(t+0.34)+(1-t-0.34)*j/5)]
    );
module raw_tread_outline() {
    polygon([for(i=[0:lug_count-1]) each
        (reverse_teeth ? paired_tooth_points(i) :
            concat([tooth_tip(i)],
                [for(j=[0:19]) main_flank(i,j/20)]))]);
}

// Round only concave valleys. This dilation/erosion fills inward corners
// while preserving sharp convex peaks on the forward and reverse teeth.
module tread_outline() {
    offset(r=-valley_fillet_radius,$fn=48)
        offset(r=valley_fillet_radius,$fn=48)
            raw_tread_outline();
}

// The cavity is entirely enclosed. Radial bridges create separate chambers.
module tread_cavity() {
    translate([0,0,rim_wall]) linear_extrude(height=wheel_width-2*rim_wall,convexity=20)
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
    linear_extrude(height=wheel_width,convexity=20) difference() {
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
        cube([sleeve_length+1,5,8]);
    color("#b8c3cc") radial_cylinder(hub_r+sleeve_length-2,inner_r-hub_r-sleeve_length,1.1);
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
