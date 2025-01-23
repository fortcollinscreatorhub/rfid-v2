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

include <mounting.scad>;

color([1, 1, 1, 0.15]) {
    #
    translate([0, 0, 0]) {
        linear_extrude(height=3+epsilon) {
            layer_0_screws();
        }
    }
    translate([0, 0, 3]) {
        linear_extrude(height=3+epsilon) {
            layer_1_heads();
        }
    }
    #
    translate([0, 0, 6]) {
        linear_extrude(height=6+epsilon) {
            layer_2_pcb(wide_usbc_cutout=true);
        }
    }
    translate([0, 0, 12]) {
        linear_extrude(height=6+epsilon) {
            layer_2_pcb(wide_usbc_cutout=false);
        }
    }
    #
    translate([0, 0, 18]) {
        linear_extrude(height=3+epsilon) {
            layer_3_coil();
        }
    }
    translate([0, 0, 21]) {
        linear_extrude(height=3+epsilon) {
            layer_4_top();
        }
    }
    #
    translate([0, -box_h / 2 + face_to_cage_dy, 21]) {
        rotate(90 - cage_side_half_angle) {
            for (r = [0, 1]) {
                rotate([0, 0, r * cage_side_angle])
                rotate([90, 0, 0])
                translate([cage_side_finger_joint_offset, 0, 0])
                translate([0, cage_side_h, cage_thickness / 2])
                rotate([180, 0, 0])
                linear_extrude(height=3+epsilon) {
                    cage_side();
                }
            }
        }
    }
    translate([0, -box_h / 2 + face_to_cage_dy, 24 + cage_side_h - (2 * cage_thickness)]) {
        linear_extrude(height=3+epsilon) {
            cage_face();
        }
    }
}
