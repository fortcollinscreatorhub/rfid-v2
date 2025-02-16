// Copyright 2025 Stephen Warren <swarren@wwwdotorg.org>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

include <fob-cage.scad>;

epsilon = 0.001;
inches = 25.4;
box_w = 118; // 4.5" nominal, but measures taller.
box_h = 115; // 4.5" nominal, and measures that.
box_padding = 0.25 * inches;
box_layer_m1_padding = 20;
box_nut_padding = inches / 10;
box_corner_r = 2;
barrel_nut_r = 5 / 2;
barrel_nut_cutout_r = 9.5 / 2; // Measured 8.5, with some margin
barrel_screw_r = 4 / 2;
num6_screw_r = 3.75 / 2;
num6_head_r = 9 / 2;
num8_screw_r = 4.39 / 2;
num8_head_r = 10 / 2;
gang_dx_high = 1.875 * inches;
gang_dx_low = 1.811 * inches;
gang_h = 3.281 * inches;
four_inch_screw_positions = [
    [-43.4, 42.9],
    [42.8, -42.9]
];
pcb_cutout_margin_r = 1;
pcb_w = 90;
pcb_h = 45;
// 1.90" ESP module; it's slightly larger:
esp32_w = 63.8;
esp32_h = 31.5;
esp32_right_inset = -1.5;
pcb_to_esp32_x = ((pcb_w - esp32_w) / 2) + esp32_right_inset;
pcb_to_esp32_y = (pcb_h - esp32_h) / 2;
usbc_w = 1.5;
usbc_h = 12;
esp32_to_usbc_x = ((esp32_w + usbc_w) / 2) - epsilon;
esp32_to_usbc_y = 0;
pcb_wire_cutout_w = 30;
pcb_wire_cutout_h = 20;
pcb_to_wire_cutout_x = ((-pcb_w + pcb_wire_cutout_w) / 2) + 20;
pcb_to_wire_cutout_y = ((-pcb_h - pcb_wire_cutout_h) / 2) + epsilon;
// Assume center is OK:
box_to_pcb_x = 0;
box_to_pcb_y = ((box_h - pcb_h) / 2) - pcb_cutout_margin_r - box_padding;
coil_w = 47;
coil_h = 35;
coil_corner_r = 2;
coil_cutout_margin_r = 1;
coil_wire_cutout_w = 10;
coil_wire_cutout_h = 24;
coil_to_wire_cutout_x = 0;
coil_to_wire_cutout_y = ((coil_h + coil_wire_cutout_h) / 2) - 5;
face_to_cage_dy = -17;

$fa = 5;
$fs = 0.25;

module rounded_rect(w, h, corner_r) {
    dx = (w / 2) - corner_r;
    dy = (h / 2) - corner_r;
    hull() {
        for (xm = [-1, 1]) {
            for (ym = [-1, 1]) {
              translate([dx * xm, dy * ym]) circle(r=corner_r);
            }
        }
    }
}

module slot(center_spacing, r) {
    hull() {
        for (xm = [-1, 1]) {
              translate([center_spacing / 2 * xm, 0]) circle(r=r);
        }
    }
}

module outline() {
    rounded_rect(box_w, box_h, box_corner_r);
}

module barrel_nut_hole() {
    circle(r=barrel_nut_r);
}

module barrel_nut_offset_cutout() {
    r = barrel_nut_cutout_r;
    circle(r=r);
}

module barrel_screw_hole() {
    circle(r=barrel_screw_r);
}

function barrel_positions() =
    let (
        sz = max(barrel_nut_r, barrel_screw_r),
        dx = (box_w / 2) - sz - box_nut_padding,
        dy = (box_h / 2) - sz - box_nut_padding
    )
    [ for (xm = [-1, 1], ym = [-1, 1]) [dx * xm, dy * ym] ];

module barrel_nut_holes() {
    for (c = barrel_positions()) {
        translate(c) barrel_nut_hole();
    }
}

module barrel_nut_offset_cutouts() {
    for (i = [0:3]) {
        translate(barrel_positions()[i])
            rotate(i * 90)
                barrel_nut_offset_cutout();
    }
}

module barrel_screw_holes() {
    for (c = barrel_positions()) {
        translate(c) barrel_screw_hole();
    }
}

function gang_screw_positions() =
    let (dx = (gang_dx_high + gang_dx_low) / 2)
    [ for (xm = [-1, 1], ym = [-1, 1]) [dx / 2 * xm, gang_h / 2 * ym] ];

module gang_screw_slot() {
    slot(gang_dx_high - gang_dx_low, num6_screw_r);
}

module gang_screw_holes() {
    for (c = gang_screw_positions()) {
        translate(c) gang_screw_slot();
    }
}

module gang_head_slot() {
    slot(gang_dx_high - gang_dx_low, num6_head_r);
}

module gang_head_holes() {
    for (c = gang_screw_positions()) {
        translate(c) gang_head_slot();
    }
}

module four_inch_screw_holes() {
    for (c = four_inch_screw_positions) {
        translate(c) circle(r = num8_screw_r);
    }
}

module four_inch_head_holes() {
    for (c = four_inch_screw_positions) {
        translate(c) circle(r = num8_head_r);
    }
}

module pcb(do_pcb=true, do_esp32=true, do_usbc=true, wide_usbc_cutout=false) {
    if (do_pcb) {
        square(size=[pcb_w, pcb_h], center=true);
    }
    translate([pcb_to_esp32_x, pcb_to_esp32_y])  {
        if (do_esp32) {
            square(size=[esp32_w, esp32_h], center=true);
        }
        if (do_usbc) {
            w = wide_usbc_cutout
                ? (box_w - (pcb_w + pcb_to_esp32_x)) * 2.1
                : usbc_w;
            translate([esp32_to_usbc_x, esp32_to_usbc_y]) {
                square(size=[w, usbc_h], center=true);
            }
        }
    }
}

module pcb_cutout(do_pcb=true, do_esp32=true, do_usbc=true, wide_usbc_cutout=false, do_wire_cutout=true) {
    translate([box_to_pcb_x, box_to_pcb_y]) {
        offset(r=pcb_cutout_margin_r) pcb(do_pcb, do_esp32, do_usbc, wide_usbc_cutout);
        if (do_wire_cutout) {
            translate([pcb_to_wire_cutout_x, pcb_to_wire_cutout_y]) {
                square(size=[pcb_wire_cutout_w, pcb_wire_cutout_h], center=true);
            }
        }
    }
}

module coil() {
    offset(r=coil_cutout_margin_r) {
        rounded_rect(coil_w, coil_h, coil_corner_r);
    }
}

module coil_cutout() {
    box_to_coil_y = (-(box_h - coil_h) / 2) + coil_cutout_margin_r + box_padding;
    translate([0, box_to_coil_y]) {
        coil();
        translate([coil_to_wire_cutout_x, coil_to_wire_cutout_y]) {
            square(size=[coil_wire_cutout_w, coil_wire_cutout_h], center=true);
        }
    }
}

module layer_m1_offset_ring() {
    difference() {
        outline();
        offset(r=-box_layer_m1_padding) outline();
        gang_screw_holes();
        four_inch_screw_holes();
        barrel_nut_offset_cutouts();
    }
}

module layer_0_screws() {
    difference() {
        outline();
        barrel_nut_holes();
        gang_screw_holes();
        four_inch_screw_holes();
        pcb_cutout(do_pcb=false, do_esp32=false, do_usbc=false, do_wire_cutout=true);
    }
}

module layer_1_heads() {
    difference() {
        outline();
        barrel_nut_holes();
        gang_head_holes();
        four_inch_head_holes();
        pcb_cutout(do_pcb=false, do_esp32=false, do_usbc=false, do_wire_cutout=true);
    }
}


module layer_2_pcb(wide_usbc_cutout) {
    difference() {
        outline();
        barrel_nut_holes();
        pcb_cutout(wide_usbc_cutout = wide_usbc_cutout);
    }
}

module layer_3_coil() {
    difference() {
        outline();
        barrel_screw_holes();
        pcb_cutout(do_pcb=false, do_usbc=false, do_wire_cutout=false);
        coil_cutout();
    }
}

module layer_4_top() {
    difference() {
        outline();
        barrel_screw_holes();
        translate([0, -box_h / 2 + face_to_cage_dy]) cage_mount_holes();
    }
}
