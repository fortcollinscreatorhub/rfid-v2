// A mounting cover for a 12v dc power brick that's used to power the RFID latch locker
// Printed w/ PLA is fine probably. We'll see.
//

// Power Supply Dimensions
psu_length = 120.5;
psu_width  = 51.5;
psu_height = 35.0;

// Housing settings
wall_thick = 2.4;       
tolerance  = 1.0; 
corner_radius = 3.0;    // Radius of the outside vertical edges

// Mounting Tab Settings
mount_hole_dia = 3.5;       // Screw shaft size
head_dia       = 6;       // Screw head size (Counterbore)
head_depth     = 5.0;       // Depth of screw head recess
tab_stick_out  = 14.0;      // How far the tab extends out
tab_length     = 30.0;      // Width of the tab along the wall

// Input Power Cord Slot (Centered)
slot1_width = 17.0;
slot1_depth = 22.0;    

// DC Output Cord Slot (Offset)
slot2_width = 14.0;
slot2_depth = 20.0;
slot2_offset = 7;    

// Ventilation
vent_width = 4;
vent_gap = 4;

// --- Calculated Values ---
inner_l = psu_length + tolerance;
inner_w = psu_width + tolerance;
inner_h = psu_height + tolerance; 

outer_l = inner_l + (wall_thick * 2);
outer_w = inner_w + (wall_thick * 2);
outer_h = inner_h + wall_thick; 

// --- Main Render ---

difference() {
    union() {
        // 1. Main Housing Body (Rounded)
        translate([0, 0, outer_h/2])
            rounded_box(outer_l, outer_w, outer_h, corner_radius);
            
        // 2. Gusseted Tabs
        generate_pocket_tabs();
    }

    // 3. Hollow out the inside (Sharp corners for the brick)
    translate([-inner_l/2, -inner_w/2, -1])
        cube([inner_l, inner_w, inner_h + 1]);

    // 4. Slot 1: Power Cord
    translate([-outer_l/2 - 5, -slot1_width/2, -1])
        cube([wall_thick + 10, slot1_width, slot1_depth + 1]);

    // 5. Slot 2: DC Out
    // MIRRORED: Measured from the -Y edge
    translate([outer_l/2 - wall_thick - 5, -(inner_w/2) + slot2_offset, -1])
        cube([wall_thick + 10, slot2_width, slot2_depth + 1]);

    // 6. Rounded Vents
    generate_side_vents();
    generate_top_vents();
}

// --- Modules ---

module rounded_box(len, wid, hei, rad) {
    x_pos = (len/2) - rad;
    y_pos = (wid/2) - rad;
    
    hull() {
        translate([-x_pos, -y_pos, -hei/2]) cylinder(r=rad, h=hei, $fn=50);
        translate([x_pos, -y_pos, -hei/2])  cylinder(r=rad, h=hei, $fn=50);
        translate([-x_pos, y_pos, -hei/2])  cylinder(r=rad, h=hei, $fn=50);
        translate([x_pos, y_pos, -hei/2])   cylinder(r=rad, h=hei, $fn=50);
    }
}

module generate_pocket_tabs() {
    translate([0, -outer_w/2, 0]) 
        make_pocket_tab();

    translate([0, outer_w/2, 0]) 
        rotate([0,0,180]) make_pocket_tab();
}

module make_pocket_tab() {
    sink = 2.0; 
    gusset_height = tab_stick_out;
    base_h = 2.0; 
    
    difference() {
        // 1. Solid Ramp
        hull() {
            translate([-tab_length/2, -tab_stick_out, 0])
                cube([tab_length, tab_stick_out + sink, base_h]); 
            
            translate([-tab_length/2, sink, gusset_height + base_h])
                cube([tab_length, 0.1, 0.1]);
        }
        
        // 2. Screw Shaft Slot
        hull() {
            translate([-2, -tab_stick_out/2, -1])
                cylinder(h=gusset_height + 5, d=mount_hole_dia, $fn=30);
            translate([2, -tab_stick_out/2, -1])
                cylinder(h=gusset_height + 5, d=mount_hole_dia, $fn=30);
        }

        // 3. Counterbore Pocket
        hull() {
            translate([-2, -tab_stick_out/2, base_h + head_depth]) 
                cylinder(h=gusset_height, d=head_dia, $fn=30);
            translate([2, -tab_stick_out/2, base_h + head_depth]) 
                cylinder(h=gusset_height, d=head_dia, $fn=30);
            
            translate([-2, -tab_stick_out/2, head_depth])
                cylinder(h=1, d=head_dia, $fn=30);
            translate([2, -tab_stick_out/2, head_depth])
                cylinder(h=1, d=head_dia, $fn=30);
        }
    }
}

module generate_side_vents() {
    start_height = tab_stick_out + 4; 
    safe_length = inner_l - (2 * corner_radius) - 10;
    
    count = floor(safe_length / (vent_width + vent_gap));
    start_x = -((count * (vent_width + vent_gap)) / 2) + (vent_width/2);
    
    r = vent_width / 2;
    h_vent = inner_h - start_height - 5;
    
    for (i = [0 : count-1]) {
        x_pos = start_x + (i * (vent_width + vent_gap));
        
        // Use hull of 2 cylinders to make a pill shape (vertical slot)
        // Oriented to cut through Y axis
        translate([x_pos + r, 0, 0]) { // Shift X by radius to center the hull
            hull() {
                // Bottom of slot
                translate([0, -outer_w/2 - 5, start_height + r])
                    rotate([-90, 0, 0])
                    cylinder(r=r, h=outer_w + 10, $fn=20);
                
                // Top of slot
                translate([0, -outer_w/2 - 5, start_height + h_vent - r])
                    rotate([-90, 0, 0])
                    cylinder(r=r, h=outer_w + 10, $fn=20);
            }
        }
    }
}

module generate_top_vents() {
    safe_length = inner_l - (2 * corner_radius) - 10;
    
    count = floor(safe_length / (vent_width + vent_gap));
    start_x = -((count * (vent_width + vent_gap)) / 2) + (vent_width/2);
    
    r = vent_width / 2;
    len_vent = inner_w - 10;
    
    for (i = [0 : count-1]) {
        x_pos = start_x + (i * (vent_width + vent_gap));
        
        // Use hull of 2 cylinders to make a pill shape (horizontal slot)
        // Oriented to cut through Z axis
        translate([x_pos + r, 0, 0]) {
            hull() {
                // Front end (-Y)
                translate([0, -inner_w/2 + 5 + r, outer_h - wall_thick - 1])
                    cylinder(r=r, h=wall_thick + 2, $fn=20);
                
                // Back end (+Y)
                translate([0, -inner_w/2 + 5 + len_vent - r, outer_h - wall_thick - 1])
                    cylinder(r=r, h=wall_thick + 2, $fn=20);
            }
        }
    }
}