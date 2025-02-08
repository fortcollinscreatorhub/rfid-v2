# What's in this directory

A design for a box to contain the PCB, and to attach to a piece of equipment.
It's designed to screw into any of:
* A 4" weather-proof box. Good fit. E.g.
  https://www.homedepot.com/p/Commercial-Electric-2-Gang-Metallic-Weatherproof-Box-with-5-3-4-in-Holes-Gray-WDB575G/300846319
* A 2-gang electrical box. Overhangs a bit. E.g.
  https://www.homedepot.com/p/Southwire-4-in-W-x-2-1-8-in-D-Steel-Metallic-2-Gang-Square-Switch-Box-Six-1-2-in-KO-s-Two-3-4-KO-s-and-Four-CKO-s-MGSB-2-UPC/324509229
* A 4" electrical box. Overhangs a bit. E.g.
  https://www.homedepot.com/p/Steel-City-4-in-30-3-cu-in-Metallic-Square-Box-521711234EW-25R/202590467

The design uses [OpenSCAD](https://openscad.org/). Run `render-2d.sh` (under
Linux or WSL2) to render the result.

The layers should be attached using barrel screws (also known as binding
posts, chicago screws, sex screws, and probably other names). Insert these
from the back before mounting to the electrical box. For example:
https://www.amazon.com/dp/B0D5HP8TXD (M4x12mm, 5x20mm).

You could use M3/4 metal inserts or other nuts/bolts if you want. If so,
you'll need to adjust barrel_nut_r/barrel_screw_r in the .scad file to match,
and perhaps also adjust which layers use barrel_nut_holes vs.
barrel_screw_holes.

Layer -1 should be made from thin acrylic; perhaps 1mm, perhaps 3mm. Layers 0,
1, 3, 4 should be made from 3mm acrylic. Layer 2 should be made from 6mm
acrylic to save time, but can also be made from 3mm acrylic if you make more
copies. For layer 2, most likely you will need 2 6mm copies and 1 3mm copy, or
5 3mm copies.

Layer -1 allows the box to seal completely against the box it's screwed to,
since the ends of the barrel nuts stick out a fair way from the box.
Alternatively, you could glue together layers 0 and 1, then move the barrel nut
cutouts to layer 0...

Layers -1 and 0 should be screwed onto the electrical box. Other layers will be
held on by the barrel screws.

The RFID "cage" pieces should be glued into layer 4 using Weldon #4:
https://www.amazon.com/dp/B00TCUJ7A8.
