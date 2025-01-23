#!/bin/bash

# Copyright 2019-2025 Stephen Warren <swarren@wwwdotorg.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

scad=render-2d.scad
svg=render-2d.svg

cd -- "$(dirname -- "$0")"

openscad \
    --render \
    -o "${svg}" \
    "${scad}"

sed -E '/^<svg /s/ width="([0-9]+)" / width="\1mm" /' -i "${svg}"
sed -E '/^<svg /s/ height="([0-9]+)" / height="\1mm" /' -i "${svg}"
sed -E 's/stroke="black" fill="lightgray" stroke-width="0.5"/style="vector-effect:non-scaling-stroke;fill:none;fill-opacity:1;stroke:#000000;stroke-width:0.264583;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;-inkscape-stroke:hairline"/' -i "${svg}"
