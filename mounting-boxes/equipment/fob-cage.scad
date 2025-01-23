// Copyright 2025 Stephen Warren <swarren@wwwdotorg.org>
// Reverse-engineered from a design by Steve Undy
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

// Configuration:
epsilon = 0.001;
cage_thickness = 3.108;
cage_side_fingers = 7;
cage_side_units = (cage_side_fingers * 2) - 1;
cage_finger_joint_total_len = 85;
cage_side_h = 16;
cage_unit_len = cage_finger_joint_total_len / cage_side_units;
cage_top_w = 18;
cage_side_finger_joint_offset = 24;
cage_side_angle = 56;
cage_cc_w = 65;
cage_cc_h = 1;
cage_face_to_rfid_hole_scale = 0.45;
cage_face_to_rfid_hole_len = 37;
cage_face_slot_w = 6;
// Should really calculate this as distance to the center of rfid hole...
cage_face_slot_h = 50;
cage_face_slot_chamfer_scale = 0.94;

// Derived:
cage_side_half_angle = cage_side_angle / 2;
cage_cage_face_body_dy = cage_thickness / 2;
// t=o/a, a=o/tan, angle=cage_side_angle/2 (triangle-mid-angle)
cage_cage_face_body_dx = cage_cage_face_body_dy / tan(cage_side_half_angle);
cage_cage_face_body_dxy = [cage_cage_face_body_dx, cage_cage_face_body_dy];
cage_face_rfid_dxy = cage_cage_face_body_dxy / norm(cage_cage_face_body_dxy) * cage_face_to_rfid_hole_len;

module cage_unit() {
    translate([-epsilon/2, -epsilon/2]) {
        square(size=[cage_unit_len + epsilon, cage_thickness + epsilon], center=false);
    }
}

module cage_mount_holes_one_edge() {
    translate([cage_side_finger_joint_offset, 0]) {
        cage_unit();
        translate([cage_finger_joint_total_len - cage_unit_len, 0]) {
            cage_unit();
        }
    }
}

module cage_mount_holes() {
    rotate(90-cage_side_half_angle) {
        translate([0, -cage_thickness/2]) cage_mount_holes_one_edge();
        rotate([0, 0, cage_side_angle]) {
            translate([0, -cage_thickness/2]) cage_mount_holes_one_edge();
        }
    }
}

module cage_side_body() {
    square(size=[cage_finger_joint_total_len, cage_side_h], center=false);
}

module cage_fingers() {
    for (i=[0:cage_side_fingers - 1]) {
        translate([cage_unit_len * 2 * i, 0]) {
            cage_unit();
        }
    }
}

module cage_fingers_inverted() {
    difference() {
        square(size=[cage_finger_joint_total_len, cage_thickness], center=false);
        cage_fingers();
    }
}

cage_side_inter_hole_cutout_len = cage_finger_joint_total_len - (2 * cage_unit_len);
module cage_side_inter_hole_cutout() {
    square(size=[cage_side_inter_hole_cutout_len, cage_thickness + epsilon], center=false);
}

module cage_side_cage_cc_slot_cutout() {
    square(size=[cage_cc_w, cage_cc_h + epsilon], center=false);
}

module cage_side() {
    ihc_dx = cage_unit_len;
    ihc_dy = cage_side_h - cage_thickness;
    cage_cc_dx = (cage_finger_joint_total_len - cage_cc_w) / 2;
    cage_cc_dy = cage_side_h - (cage_thickness + cage_cc_h);
    difference() {
        cage_side_body();
        translate([0, -epsilon]) cage_fingers_inverted();
        translate([ihc_dx, ihc_dy]) cage_side_inter_hole_cutout();
        translate([cage_cc_dx, cage_cc_dy]) cage_side_cage_cc_slot_cutout();
    }
}

module cage_top() {
    square(size=[cage_top_w, cage_side_h - (2 * cage_thickness)], center=false);
}

module cage_face_body() {
    side_len = cage_side_finger_joint_offset + cage_finger_joint_total_len - cage_cage_face_body_dx;
    hull()  {
        square([side_len, epsilon], center=false);
        rotate(cage_side_angle) square([side_len, epsilon], center=false);
    }
}

module cage_face_fob_cutout() {
    translate(cage_face_rfid_dxy) {
        scale([cage_face_to_rfid_hole_scale, cage_face_to_rfid_hole_scale, 1]) {
            cage_face_body();
        }
    }
}

module cage_face_slot_cutout() {
    rotate(cage_side_half_angle) {
        translate([0, -cage_face_slot_w / 2]) {
            square(size=[cage_face_slot_h, cage_face_slot_w], center=false);
        }
    }
}

module cage_face_slot_chamfer() {
    adj_over_hypot = cage_cage_face_body_dxy[0] / norm(cage_cage_face_body_dxy);
    s = (cage_side_finger_joint_offset - cage_cage_face_body_dx) * adj_over_hypot * cage_face_slot_chamfer_scale * 2;
    rotate(cage_side_half_angle + 45) {
        square(size=[s, s], center=true);
    }
}

module cage_face_bottom_cutoff() {
    adj_over_hypot = cage_cage_face_body_dxy[0] / norm(cage_cage_face_body_dxy);
    s = (cage_side_finger_joint_offset - cage_cage_face_body_dx) * adj_over_hypot * 2;
    rotate(cage_side_half_angle) {
        square(size=[s, s], center=true);
    }
}

module cage_face_fingers() {
    translate([cage_side_finger_joint_offset, -cage_thickness/2]) cage_fingers_inverted();
    rotate([0, 0, cage_side_angle]) {
        translate([cage_side_finger_joint_offset, -cage_thickness/2]) cage_fingers_inverted();
    }
}

module cage_face() {
    rotate(90-cage_side_half_angle) {
        translate(cage_cage_face_body_dxy) {
            difference() {
                cage_face_body();
                cage_face_fob_cutout();
                cage_face_slot_cutout();
                cage_face_slot_chamfer();
                cage_face_bottom_cutoff();
            }
        }
        cage_face_fingers();
    }
}
