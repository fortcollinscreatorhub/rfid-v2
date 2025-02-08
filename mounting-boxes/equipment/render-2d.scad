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

translate([-1 * box_w * 1.25, 0]) layer_m1_offset_ring();
translate([0 * box_w * 1.25, 0]) layer_0_screws();
translate([1 * box_w * 1.25, 0]) layer_1_heads();
translate([3 * box_w * 1.25, 0]) layer_2_pcb(wide_usbc_cutout=true);
translate([2 * box_w * 1.25, 0]) layer_2_pcb(wide_usbc_cutout=false);
translate([4 * box_w * 1.25, 0]) layer_3_coil();
translate([5 * box_w * 1.25, 0]) layer_4_top();
translate([5.8 * box_w * 1.25, 0]) cage_side();
translate([5.8 * box_w * 1.25, -cage_side_h]) cage_top();
translate([7 * box_w * 1.25, -box_h/2]) cage_face();
