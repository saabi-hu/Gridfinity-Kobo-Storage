// Gridfinity bin that holds a Kobo Clara Color lying flat.
// Self-contained: needs no external OpenSCAD libraries.
// All dimensions in millimetres.

/* [Device] */
// Kobo Clara Color, long side
device_length = 144;
// Kobo Clara Color, short side
device_width = 112;
// Kobo Clara Color thickness (add your cover's thickness if you use one)
device_thickness = 9.2;
// Gap between the device and the pocket wall, per side
clearance = 1.0;
// Corner radius of the pocket
pocket_corner_radius = 6;

/* [Bin] */
// Grid units along X (42 mm each)
grid_x = 4;
// Grid units along Y (42 mm each)
grid_y = 3;
// Height in 7 mm units, base included (max 6 for a 57 mm drawer with a 5 mm baseplate)
height_units = 3;
// Add the Gridfinity stacking lip on top
stacking_lip = true;
// Height of the solid floor, measured from the bottom of the bin
floor_top = 7;

/* [Finger notches] */
// Width of the notch at the rim
notch_width = 40;
// Material left between the notch bottom and the floor
notch_floor_margin = 2;

/* [Hidden] */
$fn = 64;
pitch = 42;
cell = 41.5;            // one cell of the bin, 0.5 mm smaller than the grid
outer_radius = 3.75;
base_height = 4.75;     // 0.8 chamfer + 1.8 vertical + 2.15 chamfer
lip_height = 4.4;       // 0.7 chamfer + 1.8 vertical + 1.9 chamfer
eps = 0.01;

bin_x = grid_x * pitch - 0.5;
bin_y = grid_y * pitch - 0.5;
bin_top = height_units * 7;

pocket_x = device_length + 2 * clearance;
pocket_y = device_width + 2 * clearance;

assert(pocket_x <= bin_x - 2 * 2.6, "Pocket too long for the grid, raise grid_x");
assert(pocket_y <= bin_y - 2 * 2.6, "Pocket too wide for the grid, raise grid_y");
assert(bin_top - floor_top >= device_thickness, "Pocket too shallow, raise height_units");

// Rounded rectangle slab, centred on XY, of thickness h starting at z.
module rrect(x, y, r, h, z = 0) {
    translate([0, 0, z])
        linear_extrude(h)
            offset(r = r) square([x - 2 * r, y - 2 * r], center = true);
}

// Rounded rectangle inset from the outer bin outline.
module inset_slab(inset, z, h = eps) {
    rrect(bin_x - 2 * inset, bin_y - 2 * inset, max(outer_radius - inset, 0.5), h, z);
}

// Standard Gridfinity foot for one grid cell.
module foot() {
    // (inset from cell edge, z)
    layers = [[2.95, 0], [2.15, 0.8], [2.15, 2.6], [0, base_height]];
    for (i = [0 : len(layers) - 2])
        hull() {
            for (l = [layers[i], layers[i + 1]])
                rrect(cell - 2 * l[0], cell - 2 * l[0],
                      max(outer_radius - l[0], 0.8), eps, l[1]);
        }
}

module feet() {
    for (ix = [0 : grid_x - 1], iy = [0 : grid_y - 1])
        translate([(ix - (grid_x - 1) / 2) * pitch,
                   (iy - (grid_y - 1) / 2) * pitch, 0])
            foot();
}

// Cavity that forms the inside of the stacking lip.
module lip_cavity() {
    layers = [[2.6, 0], [1.9, 0.7], [1.9, 2.5], [0.4, lip_height]];
    for (i = [0 : len(layers) - 2])
        hull() {
            for (l = [layers[i], layers[i + 1]])
                inset_slab(l[0], bin_top + l[1]);
        }
    inset_slab(0.4, bin_top + lip_height - eps, 1);
}

module pocket() {
    rrect(pocket_x, pocket_y, pocket_corner_radius,
          bin_top + lip_height - floor_top + 1, floor_top);
}

// Scooped notches in both long walls so the device can be pinched out.
module finger_notches() {
    top = bin_top + (stacking_lip ? lip_height : 0);
    depth = top - (floor_top + notch_floor_margin);
    translate([0, 0, top])
        rotate([90, 0, 0])
            scale([notch_width / 2 / depth, 1, 1])
                cylinder(r = depth, h = bin_y + 2, center = true);
}

module kobo_bin() {
    difference() {
        union() {
            feet();
            inset_slab(0, base_height - eps, bin_top - base_height + eps);
            if (stacking_lip)
                inset_slab(0, bin_top - eps, lip_height + eps);
        }
        if (stacking_lip) lip_cavity();
        pocket();
        finger_notches();
    }
}

kobo_bin();
