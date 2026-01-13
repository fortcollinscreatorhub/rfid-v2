// ==========================================
//    RFID - V2 Enclosure w/ Buck Converter
// ==========================================
// 
// This script generates a custom 3D-printable enclosure for an RFID reader,
// designed to house a controller PCB, buck converter, and DC jack in a 
// compact, modular base.
//
// All the pieces are:
// - The base. 
// -- Uses clip tabs to hold down the controller board since it doesn't have mounting holes 
// -- Screw posts for buck converter
// - The lid. W/ opening for LCD and recessed cavity for RFID antenna. 
// - A cover for the RFID antenna mounted inside the lid. Should glue over that slot.
// - A cover for the banana jack housing. I'm using the one that came w/ the power brick.
// - An external cover for the male end of DC jack that plugs into that.
// - A plug (need 2x) to cover the boot and reset buttons on the controller board

$fn = 60;

// This can help isolate rendering different modules in case you want to 
// export STL separately. If you choose "all" then everything will be rendered
// at once and you can split apart in slicer.
//
part_to_show = "all"; // Options: "base", "lid", "dc_lid", "jack_cover", "antenna_cover", "cable_clamp", "plugs", "inserts", "all", "closed", "cutaway"

// The FCCH RFID-V2 main board. Snap toggles hold it in place
pcb_width = 45.2;
pcb_length = 90.2;
pcb_thickness = 1.6;

// LM2596 generic Buck Converter
buck_width = 43;      
buck_length = 21;     
buck_hole_dist_x = 31;
buck_hole_dist_y = 16; 
buck_hole_dia = 2.0;
buck_elevation = 5;

// DC Jack Internal Compartment to securely hold the jack in place
//
dc_comp_inner_w = 15;  
dc_comp_inner_l = 33;  
dc_jack_hole = 8;   
dc_slot_size = 10.5;   

// Main board USB opening
enable_usb_slot = true;
usb_slot_width = 12;   
usb_slot_height = 6;   
usb_z_adjust = 5;    

// Layout and spacing
side_padding_x = 9.0; 
pcb_vertical_margin = 1.0; 
col_spacing = 8;        
row_spacing = 8;     
dc_jack_height = 12.25; 

// Positioning parameters for rfid antenna within lid
rfid_ant_w = 47.5; rfid_ant_l = 36.5; rfid_ant_depth = 2.25;
rfid_pos_x = 43; rfid_pos_y = 21; 

// Cutouts for main board lcd, boot and reset buttons
lcd_width = 25; lcd_height = 38;
button_diameter = 6; button_spacing = 16.5;
lcd_pos_x = 15.8; lcd_pos_y = 20;
buttons_center_x = lcd_pos_x + (lcd_width / 2); 
buttons_center_y = 11;

// Tabs holding main pc board in base
enable_mounting_tabs = true;
tab_protrusion = 10;
tab_width = 15;
tab_hole_dia = 4.5;
tab_thickness = 3.0;

// Various mounting helpers
post_diameter = 8;
pin_diameter = 5.2;
screw_hole_inner = 2.8;
screw_hole_outer = 3.4;
screw_thread_depth = 12;

// Cover for external dc power supply jack in comboniation with Jack Cover below
lock_pin_dia = 2.4;       
lock_travel_y = 3.5;
boss_w = dc_jack_hole + 10; 
// boss_h calculated in Engine
boss_depth = 4.0;         
lock_tolerance = 0.3;

// Jack Cover Settings
jack_plug_length = 26;
jack_plug_dia = 10;
jack_wire_dia = 5;
cover_wall_t = 1.6;

// Some generic dimensions
wall_thickness = 2.4;
lid_thickness = 4.0; 

internal_wall_t = 1.6; 
pcb_elevation = 5;
tolerance = 0.5;
lip_depth = 2.0;
internal_height = 18; // [UPDATED] Height reduced as requested
corner_radius = 3.0;

// DC Lid Settings
dc_lid_cap_thickness = 2.0;
dc_lid_plug_depth = 2.4; 

// Logo Insert Settings
logo_tolerance = 0.1; 

// ==========================================
//            Derived Dimensions
// ==========================================

usb_slot_x_center = wall_thickness + side_padding_x + 15.5;

// Calculate Jack Z Height Globally
jack_center_z = wall_thickness + 1.25 + (dc_jack_hole / 2);

// Calculate Boss Height to reach from Z=0 to Top Clearance
boss_h = jack_center_z + (dc_jack_hole / 2) + 3.0;

// Calculate Base Requirements
col1_w = pcb_width;
col1_l = pcb_length;

buck_rot_w = buck_length; 
buck_rot_l = buck_width;  

// DC Width (Includes LEFT and RIGHT internal walls)
dc_outer_w = dc_comp_inner_w + (internal_wall_t * 2);
dc_outer_l = dc_comp_inner_l + internal_wall_t;

// Total length of DC walls including the extension to front wall
dc_wall_total_l = dc_outer_l + pcb_vertical_margin;

col2_w = max(buck_rot_w, dc_outer_w);
col2_l = dc_outer_l + row_spacing + buck_rot_l;

req_inner_w = side_padding_x + col1_w + col_spacing + col2_w + side_padding_x;
base_req_inner_l = pcb_vertical_margin + max(col1_l, col2_l) + pcb_vertical_margin;

// 3. Final Box Dimensions
max_comp_x = max(rfid_pos_x + rfid_ant_w, lcd_pos_x + lcd_width, buttons_center_x + button_spacing/2 + button_diameter/2);
max_comp_y = max(rfid_pos_y + rfid_ant_l, lcd_pos_y + lcd_height, buttons_center_y + button_diameter/2);
lid_req_outer_w = max_comp_x + wall_thickness;
lid_req_outer_l = max_comp_y + wall_thickness;

final_outer_w = max(req_inner_w + (wall_thickness*2), lid_req_outer_w);
final_outer_l = max(base_req_inner_l + (wall_thickness*2), lid_req_outer_l); 

final_inner_w = final_outer_w - (wall_thickness*2);
final_inner_l = final_outer_l - (wall_thickness*2);


// ==========================================
//            All the modules
// ==========================================

module rounded_rect(w, l, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, l-r, 0]) cylinder(h=h, r=r);
        translate([r, l-r, 0]) cylinder(h=h, r=r);
    }
}

module pcb_snap_latch() {
    clip_w = 10; clip_t = 1.6; latch_h = pcb_elevation + pcb_thickness + 1.2;
    translate([-clip_t, -clip_w/2, 0]) cube([clip_t, clip_w, latch_h]);
    translate([0, -clip_w/2, latch_h]) rotate([-90, -90, 0]) linear_extrude(clip_w) polygon([[0,0], [0, -2], [1.5, -2], [0.8, 0], [0, 0.5]]);
}

module mounting_tab(angle_rotation) {
    gusset_height = internal_height * 0.6;
    side_gusset_thickness = 2.4; 
    rotate([0,0,angle_rotation]) {
        difference() {
            union() {
                hull() {
                    translate([-tab_width/2, 0, 0]) cube([tab_width, 0.1, tab_thickness]);
                    translate([0, tab_protrusion, 0]) cylinder(h=tab_thickness, d=tab_width);
                }
                hull() {
                    translate([-tab_width/2, 0, tab_thickness]) cube([side_gusset_thickness, 0.1, gusset_height]);
                    translate([-tab_width/2, tab_protrusion, tab_thickness]) cube([side_gusset_thickness, 0.1, 0.1]);
                }
                hull() {
                    translate([tab_width/2 - side_gusset_thickness, 0, tab_thickness]) cube([side_gusset_thickness, 0.1, gusset_height]);
                    translate([tab_width/2 - side_gusset_thickness, tab_protrusion, tab_thickness]) cube([side_gusset_thickness, 0.1, 0.1]);
                }
            }
            translate([0, tab_protrusion, -1]) cylinder(h=tab_thickness + 2, d=tab_hole_dia);
        }
    }
}

module dc_compartment_lid() {
    fit_tol = 0.15; 
    
    // Tab Settings
    tab_len = 15;
    tab_dep = 5.25;
    tab_wid = 2.5;

    union() {
        // 1. The Main Cap
        cube([dc_outer_w, dc_wall_total_l, dc_lid_cap_thickness]);
        
        // 2. The Plug
        translate([internal_wall_t + fit_tol, internal_wall_t + fit_tol, -dc_lid_plug_depth]) {
            cube([
                dc_comp_inner_w - (fit_tol*2), 
                (dc_wall_total_l - (internal_wall_t*2)) - (fit_tol*2), 
                dc_lid_plug_depth
            ]);
        }
        
        // 3. Inside Top Edge Tab
        translate([
            (dc_outer_w - tab_len) / 2,     
            dc_wall_total_l - internal_wall_t - tab_wid - fit_tol, 
            -tab_dep                        
        ])
        cube([tab_len, tab_wid, tab_dep]);
    }
}


module jack_cover() {
    // 1. Calculate Internal Dimensions
    inner_w = boss_w + (lock_tolerance * 2);
    inner_h = boss_h + (lock_tolerance * 2);
    
    // 2. Calculate Depth
    internal_depth = jack_plug_length + boss_depth;
    
    // 3. Calculate External Dimensions
    cover_w = inner_w + (cover_wall_t * 2);
    cover_l = internal_depth + cover_wall_t; // Add thickness for the back wall
    cover_h_dim = inner_h + cover_wall_t;    // Add thickness for the top wall

    // Pin Positions 
    pin_z = 3.0; 
    pin_y_offset = boss_depth / 2; 

    difference() {
        // Main Block
        cube([cover_w, cover_l, cover_h_dim]);
        
        // Internal Cavity ("The Garage")
        translate([cover_wall_t, -0.1, -0.1])
            cube([inner_w, internal_depth + 0.1, inner_h]);
            
        // Wire Slot
        translate([(cover_w/2) - (jack_wire_dia/2), internal_depth - 2, -0.1])
            cube([jack_wire_dia, cover_wall_t + 10, inner_h]);
    }

    // Locking Pins
    translate([0, pin_y_offset, pin_z]) {
        translate([cover_wall_t, 0, 0]) 
            rotate([0, 90, 0]) 
            cylinder(h=1.5, d=lock_pin_dia);
        
        translate([cover_w - cover_wall_t, 0, 0]) 
            rotate([0, -90, 0]) 
            cylinder(h=1.5, d=lock_pin_dia);
    }
}

// Antenna Depression Cover
// 
module antenna_cover() {
    // Plate Dimensions (Outer Shell)
    plate_w = 50; 
    plate_l = 44;
    plate_t = 0.6;
    
    // Lip Dimensions
    lip_w = 42.75;
    lip_l = 31.75;
    lip_d = rfid_ant_depth - 0.25;      // Depth clearance
    lip_wall = 0.8; 
    lip_rad = 3.0; // Corner radius for the lip
    
    difference() {
        union() {
            // Main Plate
            cube([plate_w, plate_l, plate_t]);
            
            // The Rounded Lip (Centered relative to the plate)
            translate([(plate_w - lip_w)/2, (plate_l - lip_l)/2, -lip_d]) {
                difference() {
                    // Outer Rounded Shape
                    rounded_rect(lip_w, lip_l, lip_d, lip_rad);
                    
                    // Inner Rounded Hollow (to make it a thin rim)
                    inner_r = max(0.1, lip_rad - lip_wall);
                    
                    translate([lip_wall, lip_wall, -0.1])
                        rounded_rect(lip_w - (lip_wall*2), lip_l - (lip_wall*2), lip_d + 0.2, inner_r);
                }
            }
        }
        
        // Wire Notch
        // Centered along the long side (X-axis, 50mm)
        notch_len = 10; 
        notch_depth = 6; 
        
        translate([(plate_w - notch_len)/2, -0.1, -lip_d - 0.1])
            cube([notch_len, notch_depth + 0.1, lip_d + plate_t + 0.2]);
    }
}

// Glue-on Cable Clamp
module cable_clamp() {
    // Dimensions
    clamp_len = 6.0;       // Length of the clamp
    inner_w = 3.0;         // [UPDATED] Width
    inner_h = 1.5;         // [UPDATED] Height
    wall = 1.2;            // Wall thickness
    tab_w = 4.0;           // Width of glue tabs
    
    // Centering for convenience
    translate([-inner_w/2, 0, 0]) {
        union() {
            // 1. The Arch (U-Shape)
            difference() {
                // Outer block
                translate([-wall, 0, 0])
                    cube([inner_w + (wall*2), clamp_len, inner_h + wall]);
                
                // Inner cutout
                translate([0, -0.1, -0.1])
                    cube([inner_w, clamp_len + 0.2, inner_h + 0.1]);
            }
            
            // 2. The Glue Tabs
            // Left Tab
            translate([-wall - tab_w, 0, 0])
                cube([tab_w, clamp_len, wall]);
            
            // Right Tab
            translate([inner_w + wall, 0, 0])
                cube([tab_w, clamp_len, wall]);
        }
    }
}

// Flexible compression plug to cover the USB port in base
module plug_usb() {
    p_w = usb_slot_width - 0.3;  // Clearance width
    p_h = usb_slot_height - 0.3; // Clearance height
    
    // Thickness Control
    central_gap = 3.0; 
    
    // Stick out a bit from the wall
    shaft_len = wall_thickness + 0.8; 
    
    head_size = 2.0; 
    
    // Head
    translate([-(p_w+head_size*2)/2, -(p_h+head_size*2)/2, 0])
        rounded_rect(p_w+head_size*2, p_h+head_size*2, 1.5, 2.0);
    
    translate([0,0,1.5]) {
        // Barb Settings
        barb_h = 0.4; 
        ramp_len = 0.6; // Length of the slope
        
        // Z-Position: Start the wedge so it ends exactly at the tip
        barb_start_z = shaft_len - ramp_len;

        // Top Tab
        union() {
            translate([-p_w/2, central_gap/2, 0])
                cube([p_w, (p_h - central_gap)/2, shaft_len]);
            
            // Top Barb
            translate([-p_w/2, p_h/2, barb_start_z]) {
                rotate([0,90,0])
                // [FIXED] Polygon X goes negative to map to +Z after rotation
                // (0, barb_h) is the shoulder (Thick)
                // (-ramp_len, 0) is the tip (Thin)
                linear_extrude(p_w) polygon([[0,0], [-ramp_len, 0], [0, barb_h]]);
            }
        }
        
        // Bottom Tab
        union() {
            translate([-p_w/2, -p_h/2, 0])
                cube([p_w, (p_h - central_gap)/2, shaft_len]);
                
            // Bottom Barb
            translate([-p_w/2, -p_h/2, barb_start_z]) {
                rotate([0,90,0])
                // [FIXED] Negative Y height for bottom barb
                linear_extrude(p_w) polygon([[0,0], [-ramp_len, 0], [0, -barb_h]]);
            }
        }
    }
}

module plug_button() {
    p_dia = button_diameter - 0.2; 
    
    // Stick out 0.8mm past lid
    shaft_len = lid_thickness + .8; 
    
    head_dia = button_diameter + 4.0;
    wall_t = 0.8; // Thin walls
    
    // Head
    cylinder(h=1.5, d=head_dia);
    
    translate([0,0,1.5]) {
        difference() {
            union() {
                // Shaft
                cylinder(h=shaft_len, d=p_dia);
                
                // Low-Profile Locking Ring (Tapered)
                translate([0,0,shaft_len - 0.5])
                    cylinder(h=0.5, d1=p_dia + 0.7, d2=p_dia);
            }
            
            // Hollow Core (Bore) for flexibility
            translate([0,0,-0.1])
                cylinder(h=shaft_len + 2, d=p_dia - (wall_t*2));

            // Compression Slot 1 (Horizontal)
            translate([-(p_dia+2)/2, -0.5, -0.1])
                cube([p_dia + 2, 1.0, shaft_len + 2]);

            // Compression Slot 2 (Vertical/Perpendicular)
//            rotate([0,0,90])
//                translate([-(p_dia+2)/2, -0.5, -0.1])
//                cube([p_dia + 2, 1.0, shaft_len + 2]);
        }
    }
}

module box_base() {
    hole_offset = wall_thickness + (post_diameter/2);
    hole_positions = [[hole_offset, hole_offset], [final_outer_w - hole_offset, hole_offset], [final_outer_w - hole_offset, final_outer_l - hole_offset], [hole_offset, final_outer_l - hole_offset]];

    pcb_x = wall_thickness + side_padding_x;
    pcb_y = wall_thickness + (final_inner_l - pcb_length)/2; 

    post_left_edge_x = final_outer_w - wall_thickness - post_diameter;
    dc_x = post_left_edge_x - dc_outer_w;
    
    dc_y_ref = wall_thickness + pcb_vertical_margin; 
    dc_wall_y = wall_thickness;
    
    center_of_cavity_x = dc_x + internal_wall_t + (dc_comp_inner_w / 2);
    
    comp_wall_h = dc_jack_height + dc_lid_plug_depth;

    buck_center_x = final_outer_w - wall_thickness - side_padding_x - (col2_w/2);
    buck_center_y = dc_y_ref + dc_outer_l + row_spacing + (buck_rot_l / 2);

    jack_z = jack_center_z; 

    difference() {
        union() {
            // Outer shell
            difference() {
                rounded_rect(final_outer_w, final_outer_l, internal_height + wall_thickness, corner_radius);
                translate([wall_thickness, wall_thickness, wall_thickness])
                    rounded_rect(final_inner_w, final_inner_l, internal_height + wall_thickness, corner_radius/2);
            }
            // PC board posts
            intersection() {
                translate([wall_thickness, wall_thickness, wall_thickness])
                    rounded_rect(final_inner_w, final_inner_l, internal_height + wall_thickness, corner_radius/2);
                union() {
                    for (pos = hole_positions) {
                        translate([pos[0], pos[1], 0]) {
                            cylinder(h=(internal_height + wall_thickness) - lip_depth, d=post_diameter);
                            cylinder(h=internal_height + wall_thickness, d=pin_diameter);
                        }
                    }
                }
            }
            // DC Jack walls WALLS
            translate([dc_x, dc_wall_y, wall_thickness]) {
                cube([internal_wall_t, dc_wall_total_l, comp_wall_h]);
                translate([0, dc_wall_total_l - internal_wall_t, 0])
                    cube([dc_outer_w, internal_wall_t, comp_wall_h]);
                translate([dc_outer_w - internal_wall_t, 0, 0])
                    cube([internal_wall_t, dc_wall_total_l, comp_wall_h]);
            }

            // Screw mounts for buck converter
            bx = buck_hole_dist_y / 2; by = buck_hole_dist_x / 2; 
            translate([buck_center_x, buck_center_y, wall_thickness]) {
                for (mx = [-bx, bx]) { for (my = [-by, by]) { translate([mx, my, 0]) cylinder(h=buck_elevation, d=6); } }
            }
            
            // Posts that sit under the main board to elevate it off floor of base
            if (enable_mounting_tabs) {
                min_edge_pos = (tab_width/2) + corner_radius;
                max_edge_pos = final_outer_w - ((tab_width/2) + corner_radius);
                
                // Top Edge Tabs
                ideal_top_left = final_outer_w * 0.25; ideal_top_right = final_outer_w * 0.75;
                min_usb_clearance = (usb_slot_width/2) + (tab_width/2) + 3;
                dist_top_left = abs(ideal_top_left - usb_slot_x_center);
                final_top_left = (dist_top_left < min_usb_clearance) ? max(min_edge_pos, usb_slot_x_center - min_usb_clearance) : ideal_top_left;
                dist_top_right = abs(ideal_top_right - usb_slot_x_center);
                final_top_right = (dist_top_right < min_usb_clearance) ? min(max_edge_pos, usb_slot_x_center + min_usb_clearance) : ideal_top_right;
                translate([final_top_left, final_outer_l, 0]) mounting_tab(0);
                translate([final_top_right, final_outer_l, 0]) mounting_tab(0);

                // Bottom Edge Tabs 
                ideal_bot_left = final_outer_w * 0.25; ideal_bot_right = final_outer_w * 0.75;
                min_dc_clearance = (boss_w/2) + (tab_width/2) + 4; 
                dist_bot_left = abs(ideal_bot_left - center_of_cavity_x);
                final_bot_left = (dist_bot_left < min_dc_clearance) ? ((ideal_bot_left < center_of_cavity_x) ? max(min_edge_pos, center_of_cavity_x - min_dc_clearance) : min(max_edge_pos, center_of_cavity_x + min_dc_clearance)) : ideal_bot_left;
                dist_bot_right = abs(ideal_bot_right - center_of_cavity_x);
                final_bot_right = (dist_bot_right < min_dc_clearance) ? ((ideal_bot_right < center_of_cavity_x) ? max(min_edge_pos, center_of_cavity_x - min_dc_clearance) : min(max_edge_pos, center_of_cavity_x + min_dc_clearance)) : ideal_bot_right;
                translate([final_bot_left, 0, 0]) mounting_tab(180);
                translate([final_bot_right, 0, 0]) mounting_tab(180);
            }
            
            // PCB PADS
            translate([pcb_x, pcb_y, wall_thickness]) {
                pad_size = 6;
                translate([-1, -1, 0]) cube([pad_size+1, pad_size+1, pcb_elevation - 2.0]);
                translate([pcb_width-pad_size, -1, 0]) cube([pad_size+1, pad_size+1, pcb_elevation]);
                translate([pcb_width-pad_size, pcb_length-pad_size, 0]) cube([pad_size+1, pad_size+1, pcb_elevation]);
                translate([-1, pcb_length-pad_size, 0]) cube([pad_size+1, pad_size+1, pcb_elevation]);
                translate([0, pcb_length/2, 0]) pcb_snap_latch();
                translate([pcb_width, pcb_length/2, 0]) rotate([0,0,180]) pcb_snap_latch();
            }

            // External slotted mount structure for DC jack cable end
            translate([center_of_cavity_x - boss_w/2, -boss_depth, 0]) {
                difference() {
                    cube([boss_w, boss_depth, boss_h]);
                    
                    // Left Side Slot 
                    translate([-0.1, boss_depth/2, 0]) lock_boss_cutout();
                    
                    // Right Side Slot 
                    translate([boss_w + 0.1, boss_depth/2, 0]) mirror([1,0,0]) lock_boss_cutout();
                }
            }
        } 

        // Subtractions
        for (pos = hole_positions) { translate([pos[0], pos[1], (internal_height + wall_thickness) - screw_thread_depth]) cylinder(h=screw_thread_depth + 1, d=screw_hole_inner); }
        bx = buck_hole_dist_y / 2; by = buck_hole_dist_x / 2; 
        translate([buck_center_x, buck_center_y, wall_thickness]) { for (mx = [-bx, bx]) { for (my = [-by, by]) { translate([mx, my, 0]) cylinder(h=buck_elevation+1, d=buck_hole_dia); } } }
        
        // Two-Stage DC Hole
        // Casing Hole (Through Boss) - Wider
        translate([center_of_cavity_x, -boss_depth - 1, jack_z]) 
            rotate([-90, 0, 0]) 
            cylinder(h=boss_depth + 1.1, d=dc_jack_hole + 1.2);

        // Thread Hole (Through Wall) - Standard
        translate([center_of_cavity_x, -0.1, jack_z]) 
            rotate([-90, 0, 0]) 
            cylinder(h=wall_thickness + 20, d=dc_jack_hole);
        
        translate([center_of_cavity_x - (dc_slot_size/2), dc_y_ref + dc_outer_l - 2, jack_z - (dc_slot_size/2) + 1.5]) cube([dc_slot_size, 5, dc_slot_size]);
        
        if (enable_usb_slot) {
            usb_z = wall_thickness + pcb_elevation + usb_z_adjust;
            translate([usb_slot_x_center - (usb_slot_width/2), final_outer_l - wall_thickness - 2, usb_z]) cube([usb_slot_width, 4 + wall_thickness, usb_slot_height]);
        }
        %translate([pcb_x, pcb_y, wall_thickness + pcb_elevation]) cube([pcb_width, pcb_length, pcb_thickness]);
        translate([buck_center_x, buck_center_y, wall_thickness + buck_elevation]) rotate([0,0,90]) %translate([-buck_width/2, -buck_length/2, 0]) cube([buck_width, buck_length, pcb_thickness]);
    }
}

module box_lid() {
    difference() {
        rounded_rect(final_outer_w, final_outer_l, lid_thickness, corner_radius);
        hole_offset = wall_thickness + (post_diameter/2);
        positions = [[hole_offset, hole_offset], [final_outer_w - hole_offset, hole_offset], [final_outer_w - hole_offset, final_outer_l - hole_offset], [hole_offset, final_outer_l - hole_offset]];
        for (pos = positions) { 
            // Simple through-hole
            translate([pos[0], pos[1], -1]) { 
                cylinder(h=lid_thickness+2, d=screw_hole_outer); 
            } 
        } 
        
        translate([lcd_pos_x, lcd_pos_y, -1]) cube([lcd_width, lcd_height, lid_thickness + 2]);
        translate([buttons_center_x - button_spacing/2, buttons_center_y, -1]) cylinder(h=lid_thickness+2, d=button_diameter);
        translate([buttons_center_x + button_spacing/2, buttons_center_y, -1]) cylinder(h=lid_thickness+2, d=button_diameter);
        
        translate([rfid_pos_x - 0.2, rfid_pos_y - 0.2, lid_thickness - rfid_ant_depth]) cube([rfid_ant_w + 0.4, rfid_ant_l + 0.4, rfid_ant_depth + 0.1]);
        
        rfid_center_x = rfid_pos_x + (rfid_ant_w / 2); rfid_center_y = rfid_pos_y + (rfid_ant_l / 2);
        translate([rfid_center_x, rfid_center_y, -0.01]) rotate([0, 0, -45]) linear_extrude(height = 0.18) rfid_logo_2d();
    }
    
    translate([wall_thickness + tolerance, wall_thickness + tolerance, lid_thickness]) {
        difference() {
            rounded_rect(final_inner_w - (tolerance*2), final_inner_l - (tolerance*2), lip_depth, corner_radius/2);
            translate([2, 2, -1]) rounded_rect(final_inner_w - (tolerance*2) - 4, final_inner_l - (tolerance*2) - 4, lip_depth + 2, corner_radius/2);
            global_positions = [[wall_thickness + post_diameter/2, wall_thickness + post_diameter/2], [final_outer_w - (wall_thickness + post_diameter/2), wall_thickness + post_diameter/2], [final_outer_w - (wall_thickness + post_diameter/2), final_outer_l - (wall_thickness + post_diameter/2)], [wall_thickness + post_diameter/2, final_outer_l - (wall_thickness + post_diameter/2)]];
            for (pos = global_positions) { translate([pos[0] - (wall_thickness + tolerance), pos[1] - (wall_thickness + tolerance), -1]) cylinder(h=lip_depth+2, d=pin_diameter + tolerance); }
        }
    }
}

module rfid_logo_inserts() {
    linear_extrude(height = 0.18) 
    offset(delta = -logo_tolerance) 
    rfid_logo_2d();
}

module rfid_logo_2d() {
    $fn=60;
    union() {
        circle(d=3);
        intersection() { difference() { circle(d=13); circle(d=9); } polygon([ [0,0], [10,10], [-10,10] ]); }
        intersection() { difference() { circle(d=21); circle(d=17); } polygon([ [0,0], [15,15], [-15,15] ]); }
    }
}

module lock_boss_cutout() {
    slot_depth = 2.5; 
    
    // Vertical Entry 
    hull() {
        translate([0, 0, boss_h + 1]) 
            rotate([0, 90, 0]) 
            cylinder(h=slot_depth, d=lock_pin_dia + 0.5);
            
        translate([0, 0, 3.0]) 
            rotate([0, 90, 0]) 
            cylinder(h=slot_depth, d=lock_pin_dia + 0.5);
    }
    
    // Horizontal Lock 
    hull() {
        translate([0, 0, 3.0]) 
            rotate([0, 90, 0]) 
            cylinder(h=slot_depth, d=lock_pin_dia + 0.5);
            
        translate([0, lock_travel_y, 3.0]) 
            rotate([0, 90, 0]) 
            cylinder(h=slot_depth, d=lock_pin_dia + 0.5);
    }
}

// ==========================================
//            RENDER LOGIC
// ==========================================

if (part_to_show == "base") {
    box_base();
} else if (part_to_show == "lid") {
    box_lid();
} else if (part_to_show == "dc_lid") {
    dc_compartment_lid();
} else if (part_to_show == "jack_cover") {
    jack_cover();
} else if (part_to_show == "antenna_cover") {
    antenna_cover();
} else if (part_to_show == "cable_clamp") {
    cable_clamp();
} else if (part_to_show == "plugs") {
    // Show both plugs loose
    plug_usb();
    translate([20, 0, 0]) plug_button();
} else if (part_to_show == "inserts") {
    rfid_logo_inserts();
} else if (part_to_show == "closed") {
    box_base();
    color("white", 0.5) translate([0, final_outer_l, internal_height + (wall_thickness*2)]) rotate([180, 0, 0]) box_lid();
    
    p_edge = final_outer_w - wall_thickness - post_diameter;
    p_dc_x = p_edge - dc_outer_w;
    p_center_x = p_dc_x + internal_wall_t + (dc_comp_inner_w / 2);
    p_jack_z = wall_thickness + 1.25 + (dc_jack_hole / 2);
    c_inner_w = boss_w + (lock_tolerance * 2);
    c_cover_w = c_inner_w + (cover_wall_t * 2);
    
    color("cyan") 
        translate([p_center_x - (c_cover_w/2), 0, p_jack_z - (boss_h/2)]) 
        mirror([0,1,0]) 
        jack_cover();

} else if (part_to_show == "cutaway") {
    difference() {
        union() {
            box_base();
            color("white") translate([0, final_outer_l, internal_height + (wall_thickness*2)]) rotate([180, 0, 0]) box_lid();
        }
        translate([-50, -50, -50]) cube([final_outer_w + 100, final_outer_l/2 + 50, 200]);
    }
} else {
    // Show ALL side-by-side
    box_base(); 
    translate([final_outer_w + 15, 0, 0]) box_lid(); 
    translate([-30, 0, 0]) dc_compartment_lid();
    translate([final_outer_w + 60, -50, 0]) rfid_logo_inserts();
    
    // Ghost Cover on Jack
    p_edge = final_outer_w - wall_thickness - post_diameter;
    p_dc_x = p_edge - dc_outer_w;
    p_center_x = p_dc_x + internal_wall_t + (dc_comp_inner_w / 2);
    p_jack_z = wall_thickness + 1.25 + (dc_jack_hole / 2);
    c_inner_w = boss_w + (lock_tolerance * 2);
    c_cover_w = c_inner_w + (cover_wall_t * 2);
    
    // Loose Parts
    translate([final_outer_w - 20, -60, 0]) jack_cover();
    translate([final_outer_w + 30, -60, 0]) antenna_cover();
    translate([final_outer_w + 30, -40, 0]) cable_clamp();
    
    // Loose Plugs
    translate([final_outer_w + 60, -30, 0]) plug_usb();
    translate([final_outer_w + 80, -30, 0]) plug_button();
}