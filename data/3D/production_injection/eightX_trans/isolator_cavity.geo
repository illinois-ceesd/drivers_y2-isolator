SetFactory("OpenCASCADE");
//Geometry.CopyMeshingMethod = 1;

If(Exists(scale))
    scale_fac = scale;
Else
    scale_fac = 1.0;
EndIf

If(Exists(scale_bl))
    scale_fac_bl = scale_bl;
Else
    scale_fac_bl = 1.0;
EndIf

If(Exists(blratio))
    boundratio=blratio;
Else
    boundratio=4.0;
EndIf

If(Exists(blratiocavity))
    boundratiocavity=blratiocavity;
Else
    boundratiocavity=2.0;
EndIf

If(Exists(blratioinjector))
    boundratioinjector=blratioinjector;
Else
    boundratioinjector=2.0;
EndIf

If(Exists(injectorfac))
    injector_factor=injectorfac;
Else
    injector_factor=4.0;
EndIf

If(Exists(shearfac))
    shear_factor=shearfac;
Else
    shear_factor=4.0;
EndIf

If(Exists(isofac))
    iso_factor=isofac;
Else
    iso_factor=2.0;
EndIf

If(Exists(cavityfac))
    cavity_factor=cavityfac;
Else
    cavity_factor=4.0;
EndIf

basesize=0.0064;
basesize = basesize/scale_fac;

bigsize = basesize*4;     // the biggest mesh size 
inletsize = basesize*2;   // background mesh size upstream of the nozzle
isosize = basesize/iso_factor;       // background mesh size in the isolator
nozzlesize = basesize/6;       // background mesh size in the nozzle
cavitysize = basesize/cavity_factor; // background mesh size in the cavity region
shearsize = isosize/shear_factor;

inj_h=4.e-3;  // height of injector (bottom) from floor
inj_t=1.59e-3; // diameter of injector
inj_d = 20e-3; // length of injector
injectorsize = inj_t/injector_factor; // background mesh size in the cavity region

Printf("basesize = %f", basesize);
Printf("inletsize = %f", inletsize);
Printf("isosize = %f", isosize);
Printf("nozzlesize = %f", nozzlesize);
Printf("cavitysize = %f", cavitysize);
Printf("shearsize = %f", shearsize);
Printf("injectorsize = %f", injectorsize);
Printf("boundratio = %f", boundratio);
Printf("boundratiocavity = %f", boundratiocavity);
Printf("boundratioinjector = %f", boundratioinjector);
Printf("scale_fac = %f", scale_fac);

p = 1;
l = 1;
s = 1;


y_isolator_top = 0.01167548819733;
y_isolator_bottom = -0.0083245;


bl_thickness = 0.0015;
bl_thickness_inj = 0.00025;

// some important coordinates
x_cavity_start = 0.65163;
x_cavity_rl = 0.70163;
x_cavity_ru = x_cavity_rl + 0.02;
y_cavity_l = -0.0283245;
x_isolator_start = 0.38328;

/////////////////////
// isolator geometry
/////////////////////
p = 500;
p_cavity_front_upper = p++;
p_cavity_front_bl_bottom = p++;
p_cavity_front_bl_top = p++;
p_cavity_front_top = p++;
Point(p_cavity_front_upper) = {x_cavity_start,y_isolator_bottom,0.0,basesize};
Point(p_cavity_front_bl_bottom) = {x_cavity_start,y_isolator_bottom+bl_thickness,0.0,basesize};
Point(p_cavity_front_bl_top) = {x_cavity_start,y_isolator_top-bl_thickness,0.0,basesize};
Point(p_cavity_front_top) = {x_cavity_start,y_isolator_top,0.0,basesize};

Point(p++) = {0.63,0.01167548819733,0.0,basesize};
p_nozzle_top_end = p-1;
Point(p++) = {0.63,-0.0083245,0.0,basesize};
p_nozzle_bottom_end = p-1;
p_nozzle_bottom_bl_end = p++;
Point(p_nozzle_bottom_bl_end) = {0.63,-0.0083245+bl_thickness,0.0,basesize};
p_nozzle_top_bl_end = p++;
Point(p_nozzle_top_bl_end) = {0.63,0.01167548819733-bl_thickness,0.0,basesize};

l_nozzle_top_bl_outlet = l++;
Line(l_nozzle_top_bl_outlet) = {p_nozzle_top_end, p_nozzle_top_bl_end};
l_nozzle_outlet = l++;
Line(l_nozzle_outlet) = {p_nozzle_top_bl_end, p_nozzle_bottom_bl_end};
l_nozzle_bottom_bl_outlet = l++;
Line(l_nozzle_bottom_bl_outlet) = {p_nozzle_bottom_bl_end, p_nozzle_bottom_end};

l_isolator_bottom = l++;
l_isolator_top = l++;
l_isolator_bl_bottom = l++;
l_isolator_bl_top = l++;
l_isolator_bl_bottom_end = l++;
l_isolator_bl_top_end = l++;
l_isolator_end = l++;
l_isolator_interior_bottom = l++;
Line(l_isolator_bottom) = {p_nozzle_bottom_end,p_cavity_front_upper};
Line(l_isolator_top) = {p_nozzle_top_end,p_cavity_front_top};
Line(l_isolator_bl_bottom) = {p_nozzle_bottom_bl_end,p_cavity_front_bl_bottom};
Line(l_isolator_bl_top) = {p_nozzle_top_bl_end,p_cavity_front_bl_top};
Line(l_isolator_bl_bottom_end) = {p_cavity_front_upper,p_cavity_front_bl_bottom};
Line(l_isolator_end) = {p_cavity_front_bl_bottom,p_cavity_front_bl_top};
Line(l_isolator_bl_top_end) = {p_cavity_front_bl_top, p_cavity_front_top};

//Create lineloop of this geometry
// start on the bottom left and go around clockwise
Curve Loop(400) = { 
    l_nozzle_top_bl_outlet,
    l_isolator_top,
    l_isolator_bl_top_end,
    l_isolator_bl_top
}; 
Plane Surface(400) = {400}; // the back wall top bl

Curve Loop(500) = { 
    l_nozzle_bottom_bl_outlet,
    l_isolator_bl_bottom,
    l_isolator_bl_bottom_end,
    l_isolator_bottom
}; 
Plane Surface(500) = {500}; // the back wall bottom bl

Curve Loop(600) = { 
    l_nozzle_outlet,
    l_isolator_bl_top,
    l_isolator_end,
    l_isolator_bl_bottom
}; 
Plane Surface(600) = {600}; // the back wall interior

/////////////////////
// cavity geometry
/////////////////////

p=600;
x_combustor_start = x_cavity_ru + 0.02;
// cavity coordinates
p_cavity_front_lower = p++;
p_cavity_rear_lower = p++;
p_cavity_rear_upper = p++;
p_cavity_rear_top = p++;
Point(p_cavity_front_lower) = {x_cavity_start,y_cavity_l,0.0,basesize};
Point(p_cavity_rear_lower) = {x_cavity_rl,y_cavity_l,0.0,basesize};
Point(p_cavity_rear_upper) = {x_cavity_ru,y_isolator_bottom,0.0,basesize};
Point(p_cavity_rear_top) = {x_cavity_ru,y_isolator_top,0.0,basesize};

// boundary layer points
p_cavity_top_bl = p++;
p_cavity_front_top_wall_bl = p++;
p_cavity_inner_top_bl = p++;
p_cavity_inner_bottom_bl = p++;
p_cavity_front_upper_bl = p++;
p_cavity_front_lower_bl = p++;
p_cavity_front_lower_wall_bl = p++;
p_cavity_front_bottom_wall_bl = p++;
p_cavity_rear_lower_wall_bl = p++;
p_cavity_rear_upper_bottom_bl = p++;
p_cavity_rear_upper_top_bl = p++;
p_cavity_rear_top_inner_bottom_bl = p++;
p_cavity_rear_top_inner_top_bl = p++;

p_cavity_rear_upper_inner_top_bl = p++;
p_cavity_rear_upper_inner_bottom_bl = p++;
p_cavity_rear_upper_inner_bl = p++;
p_cavity_rear_bottom_bl = p++;
p_cavity_rear_top_wall_bl = p++;

Point(p_cavity_top_bl) = {x_cavity_start,y_isolator_top-bl_thickness,0.0,basesize};
Point(p_cavity_inner_top_bl) = {x_cavity_start+bl_thickness,y_isolator_top-bl_thickness,0.0,basesize};
Point(p_cavity_inner_bottom_bl) = {x_cavity_start+bl_thickness,y_isolator_bottom+bl_thickness,0.0,basesize};
Point(p_cavity_front_top_wall_bl) = {x_cavity_start+bl_thickness,y_isolator_top,0.0,basesize};

Point(p_cavity_front_upper_bl) = {x_cavity_start+bl_thickness,y_isolator_bottom,0.0,basesize};
Point(p_cavity_front_lower_bl) = {x_cavity_start+bl_thickness,y_cavity_l+bl_thickness,0.0,basesize};
Point(p_cavity_front_lower_wall_bl) = {x_cavity_start,y_cavity_l+bl_thickness,0.0,basesize};
Point(p_cavity_front_bottom_wall_bl) = {x_cavity_start+bl_thickness,y_cavity_l,0.0,basesize};
bl_thickness_diag = bl_thickness/Sqrt(2.);
Point(p_cavity_rear_upper_bottom_bl) = {x_cavity_ru,y_isolator_bottom+bl_thickness,0.0,basesize};
Point(p_cavity_rear_bottom_bl) = {x_cavity_rl,y_cavity_l+bl_thickness,0.0,basesize};
Point(p_cavity_rear_upper_inner_bottom_bl) = {x_cavity_ru-bl_thickness,y_isolator_bottom+bl_thickness,0.0,basesize};
Point(p_cavity_rear_upper_inner_top_bl) = {x_cavity_ru-bl_thickness,y_isolator_top-bl_thickness,0.0,basesize};
Point(p_cavity_rear_upper_inner_bl) = {x_cavity_ru-bl_thickness,y_isolator_bottom,0.0,basesize};

Point(p_cavity_rear_upper_top_bl) = {x_cavity_ru,y_isolator_top-bl_thickness,0.0,basesize};
Point(p_cavity_rear_top_wall_bl) = {x_cavity_ru-bl_thickness,y_isolator_top,0.0,basesize};

// cavity lines
l_cavity_front = l++;
l_cavity_bottom = l++;
l_cavity_rear = l++;
l_cavity_upper_top_bl = l++;
l_cavity_upper = l++;
l_cavity_upper_bottom_bl = l++;
l_cavity_top = l++;
l_cavity_inner_top = l++;
l_cavity_inner_bottom = l++;
l_cavity_top_right_bl = l++;
l_cavity_top_left_bl = l++;

Line(l_cavity_front) = {p_cavity_front_lower_wall_bl, p_cavity_front_upper};
Line(l_cavity_bottom) = {p_cavity_front_bottom_wall_bl, p_cavity_rear_lower};
Line(l_cavity_rear) = {p_cavity_rear_lower, p_cavity_rear_upper};
Line(l_cavity_upper_bottom_bl) = {p_cavity_rear_upper, p_cavity_rear_upper_bottom_bl};
Line(l_cavity_upper) = {p_cavity_rear_upper_bottom_bl,p_cavity_rear_upper_top_bl};
Line(l_cavity_upper_top_bl) = {p_cavity_rear_upper_top_bl,p_cavity_rear_top};
Line(l_cavity_top_right_bl) = {p_cavity_rear_top_wall_bl,p_cavity_rear_top};
Line(l_cavity_top) = {p_cavity_front_top_wall_bl,p_cavity_rear_top_wall_bl};
Line(l_cavity_top_left_bl) = {p_cavity_front_top,p_cavity_front_top_wall_bl};

// boundary layer lines
l_cavity_bl_top = l++;
l_cavity_bl_top_left = l++;
l_cavity_bl_top_right = l++;
l_cavity_top_wall_bl_right = l++;
l_cavity_top_wall_bl_left = l++;
l_cavity_rear_upper_bl = l++;
l_cavity_rear_wall_bl = l++;
l_cavity_bottom_bl = l++;
l_cavity_front_bl = l++;
l_cavity_inner_top_bl_top = l++;
l_cavity_inner_top_bl_right = l++;
l_cavity_inner_top_bl_bottom = l++;
l_cavity_corner_bl_top = l++;
l_cavity_corner_bl_bottom = l++;
l_cavity_corner_bl_left = l++;
l_cavity_corner_bl_right = l++;
l_cavity_rear_corner_bl = l++;
l_cavity_rear_upper_bl = l++;
l_cavity_front_upper_bl = l++;
l_cavity_rear_inner_bl_top = l++;
l_cavity_rear_inner_bl_bottom = l++;
l_cavity_rear_inner_bl_left = l++;

// 3 horizontal lines on the top bl
Line(l_cavity_bl_top_left) = {p_cavity_front_bl_top,  p_cavity_inner_top_bl};
Line(l_cavity_bl_top) = { p_cavity_inner_top_bl, p_cavity_rear_upper_inner_top_bl};
Line(l_cavity_bl_top_right) = {p_cavity_rear_upper_inner_top_bl, p_cavity_rear_upper_top_bl };

// vertical left and right on the top bl 
Line(l_cavity_top_wall_bl_left) = {p_cavity_inner_top_bl, p_cavity_front_top_wall_bl};
Line(l_cavity_top_wall_bl_right) = {p_cavity_rear_upper_inner_top_bl, p_cavity_rear_top_wall_bl};

// long bl lines that parallel the cavity edges
Line(l_cavity_front_upper_bl) = {p_cavity_inner_bottom_bl, p_cavity_inner_top_bl};
Line(l_cavity_rear_upper_bl) = {p_cavity_rear_upper_inner_bottom_bl, p_cavity_rear_upper_inner_top_bl};
Line(l_cavity_rear_wall_bl) = {p_cavity_rear_bottom_bl, p_cavity_rear_upper_inner_bl};
Line(l_cavity_bottom_bl) = {p_cavity_front_lower_bl, p_cavity_rear_bottom_bl};
Line(l_cavity_front_bl) = {p_cavity_front_lower_bl, p_cavity_front_upper_bl};

// inner square at the end of the isolator bl
Line(l_cavity_inner_top_bl_top) = {p_cavity_front_bl_bottom, p_cavity_inner_bottom_bl};
Line(l_cavity_inner_top_bl_right) = {p_cavity_front_upper_bl, p_cavity_inner_bottom_bl};
Line(l_cavity_inner_top_bl_bottom) = {p_cavity_front_upper, p_cavity_front_upper_bl};

// the bottom left corner in the cavity
Line(l_cavity_corner_bl_top) = {p_cavity_front_lower_wall_bl, p_cavity_front_lower_bl};
Line(l_cavity_corner_bl_left) = {p_cavity_front_lower, p_cavity_front_lower_wall_bl};
Line(l_cavity_corner_bl_right) = {p_cavity_front_bottom_wall_bl, p_cavity_front_lower_bl};
Line(l_cavity_corner_bl_bottom) = {p_cavity_front_lower, p_cavity_front_bottom_wall_bl};

// inner square at the beginning of the flat bl
Line(l_cavity_rear_inner_bl_top) = {p_cavity_rear_upper_inner_bottom_bl, p_cavity_rear_upper_bottom_bl};
Line(l_cavity_rear_inner_bl_bottom) = {p_cavity_rear_upper_inner_bl, p_cavity_rear_upper};
Line(l_cavity_rear_inner_bl_left) = {p_cavity_rear_upper_inner_bl, p_cavity_rear_upper_inner_bottom_bl};

Line(l_cavity_rear_corner_bl) = {p_cavity_rear_lower, p_cavity_rear_bottom_bl};
//Line(l_cavity_rear_upper_bl) = {p_cavity_rear_upper, p_cavity_rear_upper_bl};

// connect the two inner square bl regions (isolator and flat)
Line(l_cavity_inner_top) = {p_cavity_inner_bottom_bl, p_cavity_rear_upper_inner_bottom_bl};
Line(l_cavity_inner_bottom) = {p_cavity_front_upper_bl, p_cavity_rear_upper_inner_bl};


//Create cavity surfaces
Curve Loop(1000) = { 
    l_cavity_top_wall_bl_left,
    l_cavity_top,
    -l_cavity_top_wall_bl_right,
    -l_cavity_bl_top
}; 
Plane Surface(1000) = {1000}; // cavity top bl

Curve Loop(1100) = { 
    l_cavity_bl_top,
    -l_cavity_rear_upper_bl,
    -l_cavity_inner_top,
    l_cavity_front_upper_bl
}; 
Plane Surface(1100) = {1100}; // cavity interior upper

Curve Loop(1150) = { 
    l_cavity_front_bl,
    l_cavity_inner_bottom,
    -l_cavity_rear_wall_bl,
    -l_cavity_bottom_bl
}; 
Plane Surface(1150) = {1150}; // cavity interior lower

Curve Loop(1200) = {
    l_cavity_front,
    l_cavity_inner_top_bl_bottom,
    -l_cavity_front_bl,
    -l_cavity_corner_bl_top
}; 
Plane Surface(1200) = {1200}; // cavity front bl

Curve Loop(1300) = {
    -l_cavity_bottom,
    -l_cavity_corner_bl_right,
    l_cavity_bottom_bl,
    -l_cavity_rear_corner_bl
}; 
Plane Surface(1300) = {1300}; // cavity bottom bl

Curve Loop(1400) = {
    l_cavity_rear_wall_bl,
    l_cavity_rear_inner_bl_bottom,
    -l_cavity_rear,
    l_cavity_rear_corner_bl
}; 
Plane Surface(1400) = {1400}; // cavity slant wall bl

Curve Loop(1500) = {
    l_cavity_inner_top,
    -l_cavity_rear_inner_bl_left,
    -l_cavity_inner_bottom,
    l_cavity_inner_top_bl_right
}; 
Plane Surface(1500) = {1500}; // cavity upper/lower inner interface

Curve Loop(1600) = {
    -l_cavity_inner_top_bl_right,
    -l_cavity_inner_top_bl_bottom,
    l_isolator_bl_bottom_end,
    l_cavity_inner_top_bl_top
}; 
Plane Surface(1600) = {1600}; // cavity inner corner bl, connection to bottom isolator bl

Curve Loop(1700) = {
    l_cavity_corner_bl_left,
    l_cavity_corner_bl_top,
    -l_cavity_corner_bl_right,
    -l_cavity_corner_bl_bottom
}; 
Plane Surface(1700) = {1700}; // cavity front corner bl

Curve Loop(1800) = {
    l_cavity_top_left_bl,
    -l_cavity_top_wall_bl_left,
    -l_cavity_bl_top_left,
    l_isolator_bl_top_end
}; 
Plane Surface(1800) = {1800}; // cavity upper inner corner bl, connection to upper isolator bl

Curve Loop(1900) = {
    l_cavity_rear_inner_bl_top,
    -l_cavity_upper_bottom_bl,
    -l_cavity_rear_inner_bl_bottom,
    l_cavity_rear_inner_bl_left
}; 
Plane Surface(1900) = {1900}; // cavity rear inner corner bl, connection to bottom flat bl

Curve Loop(2000) = {
    l_cavity_top_wall_bl_right,
    l_cavity_top_right_bl,
    -l_cavity_upper_top_bl,
    -l_cavity_bl_top_right

}; 
Plane Surface(2000) = {2000}; // cavity upper inner corner bl, connection to top flat bl

Curve Loop(2100) = {
    l_cavity_bl_top_left,
    -l_cavity_front_upper_bl,
    -l_cavity_inner_top_bl_top,
    l_isolator_end
}; 
Plane Surface(2100) = {2100}; // cavity front upper bl

Curve Loop(2200) = {
    l_cavity_bl_top_right,
    -l_cavity_upper,
    -l_cavity_rear_inner_bl_top,
    l_cavity_rear_upper_bl
}; 
Plane Surface(2200) = {2200}; // cavity rear upper bl

////////////////////////
// cavity flat region //
////////////////////////
//

p=700;
// flat coordinates
p_expansion_start_bottom = p++;
p_expansion_start_top = p++;
Point(p_expansion_start_bottom) = {x_combustor_start,y_isolator_bottom,0.0,basesize};
Point(p_expansion_start_top) = {x_combustor_start,y_isolator_top,0.0,basesize};

// flat bl coordinates
p_cavity_expansion_start_top = p++;
p_cavity_expansion_start_bottom = p++;
p_cavity_expansion_start_top_bl = p++;
p_cavity_expansion_start_bottom_bl = p++;
Point(p_cavity_expansion_start_bottom) = {x_cavity_ru+0.02,y_isolator_bottom,0.0,basesize};
Point(p_cavity_expansion_start_bottom_bl) = {x_cavity_ru+0.02,y_isolator_bottom+bl_thickness,0.0,basesize};
Point(p_cavity_expansion_start_top) = {x_cavity_ru+0.02,y_isolator_top,0.0,basesize};
Point(p_cavity_expansion_start_top_bl) = {x_cavity_ru+0.02,y_isolator_top-bl_thickness,0.0,basesize};

// horizontal_lines
l_cavity_flat_bottom = l++;
l_cavity_flat_bottom_bl = l++;
l_cavity_flat_top = l++;
l_cavity_flat_top_bl = l++;
Line(l_cavity_flat_bottom) = {p_cavity_rear_upper, p_cavity_expansion_start_bottom};
Line(l_cavity_flat_bottom_bl) = {p_cavity_rear_upper_bottom_bl, p_cavity_expansion_start_bottom_bl};
Line(l_cavity_flat_top) = {p_cavity_rear_top, p_cavity_expansion_start_top};
Line(l_cavity_flat_top_bl) = {p_cavity_rear_upper_top_bl, p_cavity_expansion_start_top_bl};

// vertical lines
l_cavity_flat_end = l++;
l_cavity_flat_bl_bottom_end = l++;
l_cavity_flat_bl_top_end = l++;

Line(l_cavity_flat_end) = {p_cavity_expansion_start_bottom_bl, p_cavity_expansion_start_top_bl};
Line(l_cavity_flat_bl_bottom_end) = {p_cavity_expansion_start_bottom, p_cavity_expansion_start_bottom_bl};
Line(l_cavity_flat_bl_top_end) = {p_cavity_expansion_start_top_bl, p_cavity_expansion_start_top};

//Create lineloop of this geometry
// start on the bottom left and go around clockwise
Curve Loop(2400) = { 
    l_cavity_flat_top,
    -l_cavity_flat_bl_top_end,
    -l_cavity_flat_top_bl,
    l_cavity_upper_top_bl
}; 
Plane Surface(2400) = {2400}; // the back wall top bl

Curve Loop(2500) = { 
    -l_cavity_flat_bottom,
    l_cavity_upper_bottom_bl,
    -l_cavity_flat_bottom_bl,
    -l_cavity_flat_bl_bottom_end
}; 
Plane Surface(2500) = {2500}; // the back wall bottom bl

Curve Loop(2600) = { 
    l_cavity_flat_top_bl,
    -l_cavity_flat_end,
    -l_cavity_flat_bottom_bl,
    l_cavity_upper
}; 
Plane Surface(2600) = {2600}; // the back wall interior

/////////////////////////////////////////////
// Extrude the back surfaces into volumes,
// aft bl, interior, and fore-bl
/////////////////////////////////////////////

// surfaceVector contains in the following order:
// [0]	- front surface (opposed to source surface)
// [1] - extruded volume
// [n+1] - surfaces (belonging to nth line in "Curve Loop (1)") */
// aft bl

/////////////////////
// isolator geometry
/////////////////////

// isolator aft bl
iso_surf_vec_top_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{400}; };
iso_surf_vec_bottom_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{500}; };
iso_surf_vec_interior_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{600}; };

// isolator fore-aft interior
iso_surf_vec_interior_top_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{iso_surf_vec_top_bl_aft_bl[0]};};
iso_surf_vec_interior_bottom_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{iso_surf_vec_bottom_bl_aft_bl[0]};};
iso_surf_vec_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{iso_surf_vec_interior_aft_bl[0]};};

// isolator fore bl
iso_surf_vec_top_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{iso_surf_vec_interior_top_bl[0]};};
iso_surf_vec_bottom_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{iso_surf_vec_interior_bottom_bl[0]};};
iso_surf_vec_interior_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{iso_surf_vec_interior[0]};};

/////////////////////
// cavity geometry
/////////////////////

// cavity aft bl
cav_surf_vec_top_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1000}; };
cav_surf_vec_interior_upper_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1100}; };
cav_surf_vec_interior_lower_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1150}; };
cav_surf_vec_front_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1200}; };
cav_surf_vec_bottom_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1300}; };
cav_surf_vec_wall_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1400}; };
cav_surf_vec_interior_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1500}; };
cav_surf_vec_iso_lower_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1600}; };
cav_surf_vec_corner_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1700}; };
cav_surf_vec_iso_upper_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1800}; };
cav_surf_vec_flat_lower_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{1900}; };
cav_surf_vec_flat_upper_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2000}; };
cav_surf_vec_front_upper_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2100}; };
cav_surf_vec_rear_upper_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2200}; };

// cavity fore-aft interior
cav_surf_vec_interior_top_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_top_bl_aft_bl[0]};};
cav_surf_vec_interior_upper_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_interior_upper_aft_bl[0]};};
cav_surf_vec_interior_lower_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_interior_lower_aft_bl[0]};};
cav_surf_vec_interior_front_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_front_bl_aft_bl[0]};};
cav_surf_vec_interior_bottom_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_bottom_bl_aft_bl[0]};};
cav_surf_vec_interior_wall_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_wall_bl_aft_bl[0]};};
cav_surf_vec_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_interior_aft_bl[0]};};
cav_surf_vec_interior_iso_lower_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_iso_lower_bl_aft_bl[0]};};
cav_surf_vec_interior_corner_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_corner_bl_aft_bl[0]};};
cav_surf_vec_interior_iso_upper_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_iso_upper_bl_aft_bl[0]};};
cav_surf_vec_interior_flat_lower_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_flat_lower_bl_aft_bl[0]};};
cav_surf_vec_interior_flat_upper_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_flat_upper_bl_aft_bl[0]};};
cav_surf_vec_interior_front_upper_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_front_upper_bl_aft_bl[0]};};
cav_surf_vec_interior_rear_upper_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{cav_surf_vec_rear_upper_bl_aft_bl[0]};};


// cavity fore bl
cav_surf_vec_top_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_top_bl[0]};};
cav_surf_vec_interior_upper_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_upper_interior[0]};};
cav_surf_vec_interior_lower_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_lower_interior[0]};};
cav_surf_vec_front_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_front_bl[0]};};
cav_surf_vec_bottom_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_bottom_bl[0]};};
cav_surf_vec_wall_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_wall_bl[0]};};
cav_surf_vec_interior_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior[0]};};
cav_surf_vec_iso_lower_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_iso_lower_bl[0]};};
cav_surf_vec_corner_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_corner_bl[0]};};
cav_surf_vec_iso_upper_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_iso_upper_bl[0]};};
cav_surf_vec_flat_lower_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_flat_lower_bl[0]};};
cav_surf_vec_flat_upper_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_flat_upper_bl[0]};};
cav_surf_vec_front_upper_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_front_upper_bl[0]};};
cav_surf_vec_rear_upper_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{ cav_surf_vec_interior_rear_upper_bl[0]};};

/////////////////////
// cavity_flat geometry
/////////////////////

// cavity flat aft bl
flat_surf_vec_top_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2400}; };
flat_surf_vec_bottom_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2500}; };
flat_surf_vec_interior_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2600}; };

// cavity flat fore-aft interior
flat_surf_vec_interior_top_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{flat_surf_vec_top_bl_aft_bl[0]};};
flat_surf_vec_interior_bottom_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{flat_surf_vec_bottom_bl_aft_bl[0]};};
flat_surf_vec_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{flat_surf_vec_interior_aft_bl[0]};};

// cavity flat fore bl
flat_surf_vec_top_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{flat_surf_vec_interior_top_bl[0]};};
flat_surf_vec_bottom_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{flat_surf_vec_interior_bottom_bl[0]};};
flat_surf_vec_interior_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{flat_surf_vec_interior[0]};};

/////////////////////
// injector geometry
/////////////////////

// the boundary layer
// 2 half cylinders put together
Cylinder(3000) = {0.70163, -0.0283245 + inj_h + inj_t/2., 0.035/2., inj_d, 0.0, 0.0, inj_t/2.0, Pi };
injector_top[] = Symmetry { 0, -1, 0, -0.0283245 + inj_h + inj_t/2.} {Duplicata{Volume{3000};}};
// remove the cavity from the injector volume
injector[] = BooleanDifference {
    Volume{3000}; Delete;} {
    Volume{cav_surf_vec_interior_lower_interior[1]};};
injector[] = BooleanDifference {
    Volume{injector_top[]}; Delete;} {
    Volume{cav_surf_vec_interior_lower_interior[1]};};
// remove the cavity wall bl from the injector volume
injector[] = BooleanDifference {
    Volume{3000}; Delete;} {
    Volume{cav_surf_vec_interior_wall_bl[1]};};
injector[] = BooleanDifference {
    Volume{injector_top[]}; Delete;} {
    Volume{cav_surf_vec_interior_wall_bl[1]};};

// the core flow
Cylinder(3100) = {0.70163, -0.0283245 + inj_h + inj_t/2., 0.035/2., inj_d, 0.0, 0.0, inj_t/2.0-bl_thickness_inj };
// remove the cavity from the injector volume
injector_inner[] = BooleanDifference {
    Volume{3100}; Delete;} {
    Volume{cav_surf_vec_interior_lower_interior[1]};};
// remove the cavity wall bl from the injector volume
injector_inner[] = BooleanDifference {
    Volume{3100}; Delete;} {
    Volume{cav_surf_vec_interior_wall_bl[1]};};

// subtract the boundary layer volume
injector_bl1[] = BooleanDifference {
    Volume{3000}; Delete; } {
    Volume{3100}; };
// subtract the boundary layer volume
injector_bl2[] = BooleanDifference {
    Volume{injector[]}; Delete; } {
    Volume{3100}; };

/////////////////////
// nozzle modifications
/////////////////////
nozzle_start = 0.27;
nozzle_end = 0.30;

Coherence; // remove duplicate entities

box_tol = 0.0001;
fluid_volume[] = Volume In BoundingBox {
    -1., -1., -1., 2., 1., 1.
};
//
Physical Volume("fluid_domain") = {
    fluid_volume[]
};

///////////////////////////////////////////////
// edge idenfication for transfinite meshing //
///////////////////////////////////////////////
//
// anywhere below this that uses a hard-coded number is wrong
// detect the surface/edge numbering through bounding box manipulation
//


// given an array of edges, find their proper orientation
// according to the array orient based on the orientation of the
// point coordinates
// bb is the bounding box for the volume we're querying
Macro EdgeAndSurfaces

    // x0 end
    begin_save = bb[box_dir + 0];
    end_save = bb[box_dir + 3];

    bb[box_dir + 0] = begin_save - box_tol;
    bb[box_dir + 3] = begin_save + box_tol;
    surfaces[] = Surface In BoundingBox {bb[]};
    edges[] = Curve In BoundingBox { bb[] };

    // loop over all edges to determine orientation
    For j In {0:#edges[]-1}
        edge_points[] = PointsOf{Line{edges[j]};};
        p1[]=Point{edge_points[0]};
        p2[]=Point{edge_points[1]};
    
        For k In {0:2}
            If (Abs(p1[k] - p2[k]) > 1.e-10)
                If ((p1[k] - p2[k]) > 1.e-10)
                    edges[j] *= -1*edge_orient[k];
                Else
                    edges[j] *= edge_orient[k];
                EndIf
            EndIf
        EndFor
    EndFor

    bb[box_dir + 0] = end_save - box_tol;
    bb[box_dir + 3] = end_save + box_tol;
    surfaces[] += Surface In BoundingBox {bb[]};
    edges2[] = Curve In BoundingBox { bb[] };

    // loop over all edges to determine orientation
    For j In {0:#edges2[]-1}
        edge_points[] = PointsOf{Line{edges2[j]};};
        p1[]=Point{edge_points[0]};
        p2[]=Point{edge_points[1]};
    
        For k In {0:2}
            If (Abs(p1[k] - p2[k]) > 1.e-10)
                If ((p1[k] - p2[k]) > 1.e-10)
                    edges2[j] *= -1*edge_orient[k];
                Else
                    edges2[j] *= edge_orient[k];
                EndIf
            EndIf
        EndFor
    EndFor

    edges[] += edges2[];

Return

box_dir = 0;
//
// find the corner edges and surfaces on each end plane
// we do the ends of each volume
// so we only need to do every other volume for the end surfaces/edges
//

///////////////
// Isolator ///
///////////////
Printf("Isolator");
// fore/aft/top/bottom corners
//  aft-bottom
//  increase the tol a little to catch the cavity cube corner volumes
box_tol = 0.002;
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{iso_surf_vec_bottom_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

//fore-bottom
edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{iso_surf_vec_bottom_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// aft-top
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{iso_surf_vec_top_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-top
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{iso_surf_vec_top_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];
box_tol = 0.0001;
    
//Printf("bl_corner_vert_edges length = %g", #bl_corner_vert_edges[]);
//For i In {0:#bl_corner_vert_edges[]-1}
    //Printf("bl_corner_vert_edges: %g",bl_corner_vert_edges[i]);
//EndFor
//Printf("bl_corner_surfaces length = %g", #bl_corner_surfaces[]);
//For i In {0:#bl_corner_surfaces[]-1}
    //Printf("bl_corner_surfaces: %g",bl_corner_surfaces[i]);
//EndFor



//  fore/aft/top/bottom side planes/edges
//  we don't need the orientation information here, so just remove it so we can easily subtract the 
//  corner edges
//  bottom
//  increase the tol a little to catch the cavity corner volumes
box_tol = 0.002;
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{iso_surf_vec_interior_bottom_bl[1]};
bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_bottom_edges[] += Abs(edges[]);

// top
//edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{iso_surf_vec_interior_top_bl[1]};
bl_top_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_top_edges[] += Abs(edges[]);
bl_top_surfaces[] += surfaces[];

// aft
//edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{iso_surf_vec_interior_aft_bl[1]};
bl_aft_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_aft_edges[] += Abs(edges[]);
bl_aft_surfaces[] += surfaces[];

// fore
//edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{iso_surf_vec_interior_fore_bl[1]};
bl_fore_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_fore_edges[] += Abs(edges[]);
bl_fore_surfaces[] += surfaces[];
box_tol = 0.0001;

//
// remove the short edges from the fore/aft/top/bottom lists
//
bl_fore_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_aft_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_top_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_bottom_edges[] -= Abs(bl_corner_vert_edges[]); 

// 
// remove any misplaced corner surfaces from the fore/aft/top/bottom lists
//
bl_fore_surfaces[] -= bl_corner_surfaces[];
bl_aft_surfaces[] -= bl_corner_surfaces[];
bl_top_surfaces[] -= bl_corner_surfaces[];
bl_bottom_surfaces[] -= bl_corner_surfaces[];

//
// long side edges
// we can construct from the already discovered edges and the existing volumes
// 
bl_long_surfaces_isolator[] += Surface In BoundingBox { BoundingBox Volume{ iso_surf_vec_top_bl_aft_bl[1]} };
bl_long_surfaces_isolator[] += Surface In BoundingBox { BoundingBox Volume{ iso_surf_vec_bottom_bl_aft_bl[1]} };
bl_long_surfaces_isolator[] += Surface In BoundingBox { BoundingBox Volume{ iso_surf_vec_top_bl_fore_bl[1]} };
bl_long_surfaces_isolator[] += Surface In BoundingBox { BoundingBox Volume{ iso_surf_vec_bottom_bl_fore_bl[1]} };

///////////////
// Injector ///
///////////////
injector_lines[] = Curve In BoundingBox {
    .70163 + inj_h - inj_t - box_tol, -0.0283245 +inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_h + inj_t + box_tol, -0.0283245 +inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
injector_lines[] += Curve In BoundingBox {
    .70163 + inj_d - box_tol, -0.0283245 +inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_d + box_tol, -0.0283245 +inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
//Printf("injector_lines length = %g", #injector_lines[]);
//For i In {0:#injector_lines[]-1}
    //Printf("injector_lines: %g",injector_lines[i]);
//EndFor

injector_lines_vert[] = Curve In BoundingBox {
    .70163 + inj_h - inj_t - box_tol, -0.0283245 +inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_h + inj_t + box_tol, -0.0283245 +inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
injector_lines_vert[] += Curve In BoundingBox {
    .70163 +inj_d - box_tol, -0.0283245 +inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 +inj_d + box_tol, -0.0283245 +inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
//Printf("injector_lines_vert length = %g", #injector_lines_vert[]);
//For i In {0:#injector_lines_vert[]-1}
    //Printf("injector_lines_vert: %g",injector_lines_vert[i]);
//EndFor

// remove the vertical lines from the injector face
For i In {0:#injector_lines[]-1}
    id1 = injector_lines[i];
    inList = 0;
    For j In {0:#injector_lines_vert[]-1}
        id2 = injector_lines_vert[j];
        If (id1 == id2)
            inList = 1;
        EndIf
    EndFor
    If (inList == 0)
        //Printf("unique line: %g",id1);
        injector_edge[] += id1;
    EndIf
EndFor

//Printf("injector_edge length = %g", #injector_edge[]);
//For i In {0:#injector_edge[]-1}
    //Printf("injector_edge: %g",injector_edge[i]);
//EndFor

injector_surfaces[] = Surface In BoundingBox {
    .70163 + inj_h - inj_t - box_tol, -0.0283245 + inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_h + inj_t + box_tol, -0.0283245 + inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
injector_surfaces[] += Surface In BoundingBox {
    .70163 + inj_h - inj_t - box_tol, -0.0283245 + inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_h + inj_t + box_tol, -0.0283245 + inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
injector_surfaces[] += Surface In BoundingBox {
    .70163 + inj_d - box_tol, -0.0283245 + inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_d + box_tol, -0.0283245 + inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
injector_surfaces[] += Surface In BoundingBox {
    .70163 + inj_d - box_tol, -0.0283245 + inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_d + box_tol, -0.0283245 + inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
//Printf("injector_surfaces length = %g", #injector_surfaces[]);
//For i In {0:#injector_surfaces[]-1}
    //Printf("injector_surfaces: %g",injector_surfaces[i]);
//EndFor

injector_core_surfaces[] = Boundary { Volume { 3100 }; };
//Printf("injector_core_surfaces length = %g", #injector_core_surfaces[]);
For i In {0:#injector_core_surfaces[]-1}
    //Printf("injector_core_surfaces: %g",injector_core_surfaces[i]);
    injector_core_edges[] += Boundary { Surface { injector_core_surfaces[i] }; };
//EndFor


/////////////
// Cavity ///
/////////////
Printf("Cavity");
// fore/aft/top/bottom corners
//  aft-flat
//  make the tolerance a little bigger to catch the slanty edge
box_tol = 0.002;
//edge_orient[] = {1, -1, 1};
//bb[] = BoundingBox Volume{cav_surf_vec_flat_bl_aft_bl[1]};
//Call EdgeAndSurfaces;
//bl_corner_vert_edges[] += edges[];
//bl_corner_surfaces[] += surfaces[];

////fore-flat
//edge_orient[] = {1, -1, -1};
//bb[] = BoundingBox Volume{cav_surf_vec_flat_bl_fore_bl[1]};
//Call EdgeAndSurfaces;
//bl_corner_vert_edges[] += edges[];
//bl_corner_surfaces[] += surfaces[];

// aft-bottom wall
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_wall_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-bottom wall
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_wall_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// aft-bottom
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_bottom_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-bottom
edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_bottom_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];
box_tol = 0.0001;

// aft-front
box_dir = 1;
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_front_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-front
edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_front_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];
box_dir = 0;

// aft-top
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_top_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-top
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_top_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// aft-inner
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-inner
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

    
//Printf("bl_corner_vert_edges length = %g", #bl_corner_vert_edges[]);
//For i In {0:#bl_corner_vert_edges[]-1}
    //Printf("bl_corner_vert_edges: %g",bl_corner_vert_edges[i]);
//EndFor
//Printf("bl_corner_surfaces length = %g", #bl_corner_surfaces[]);
//For i In {0:#bl_corner_surfaces[]-1}
    //Printf("bl_corner_surfaces: %g",bl_corner_surfaces[i]);
//EndFor



//  fore/aft/top/bottom side planes/edges
//  we don't need the orientation information here, so just remove it so we can easily subtract the 
//  corner edges
//  flat
box_tol = 0.002;
//edge_orient[] = {1, 1, 1};
//bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
//bb[] = BoundingBox Volume{cav_surf_vec_interior_flat_bl[1]};
//Call EdgeAndSurfaces;
//bl_bottom_edges[] += Abs(edges[]);

// wall
bb[] = BoundingBox Volume{cav_surf_vec_interior_wall_bl[1]};
//bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_bottom_edges[] += Abs(edges[]);

// bottom
bb[] = BoundingBox Volume{cav_surf_vec_interior_bottom_bl[1]};
bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_bottom_edges[] += Abs(edges[]);
box_tol = 0.0001;

// front
box_dir = 1;
bb[] = BoundingBox Volume{cav_surf_vec_interior_front_bl[1]};
bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_bottom_edges[] += Abs(edges[]);
box_dir = 0;

// top
//edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_top_bl[1]};
bl_top_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_top_edges[] += Abs(edges[]);

// aft upper
//edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_upper_aft_bl[1]};
//bl_aft_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_aft_edges[] += Abs(edges[]);
bl_aft_surfaces[] += surfaces[];

// aft lower
//edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_lower_aft_bl[1]};
//bl_aft_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_aft_edges[] += Abs(edges[]);
bl_aft_surfaces[] += surfaces[];

// fore upper
//edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_upper_fore_bl[1]};
//bl_fore_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_fore_edges[] += Abs(edges[]);
bl_fore_surfaces[] += surfaces[];

// fore lower
//edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_lower_fore_bl[1]};
//bl_fore_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_fore_edges[] += Abs(edges[]);
bl_fore_surfaces[] += surfaces[];

//
// remove the short edges from the fore/aft/top/bottom lists
//
bl_fore_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_aft_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_top_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_bottom_edges[] -= Abs(bl_corner_vert_edges[]); 

// 
// remove any misplaced corner surfaces from the fore/aft/top/bottom lists
//
bl_fore_surfaces[] -= bl_corner_surfaces[];
bl_aft_surfaces[] -= bl_corner_surfaces[];
bl_top_surfaces[] -= bl_corner_surfaces[];
//bl_flat_surfaces[] -= bl_corner_surfaces[];
//bl_wall_surfaces[] -= bl_corner_surfaces[];
bl_bottom_surfaces[] -= bl_corner_surfaces[];

// 
// remove the injector core and face lines
//
bl_bottom_surfaces[] -= injector_core_surfaces[];
bl_bottom_edges[] -= injector_core_edges[];
bl_bottom_edges[] -= injector_edge[];
bl_bottom_edges[] -= injector_lines_vert[];

//
// long side edges
// we can construct from the already discovered edges and the existing volumes
// 
bl_long_surfaces_cavity_top[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_top_bl_aft_bl[1]} };
bl_long_surfaces_cavity_top[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_top_bl_fore_bl[1]} };
bl_long_surfaces_cavity_inner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_aft_bl[1]} };
bl_long_surfaces_cavity_inner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_fore_bl[1]} };
//bl_long_surfaces_cavity_flat[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_flat_bl_aft_bl[1]} };
//bl_long_surfaces_cavity_flat[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_flat_bl_fore_bl[1]} };
bl_long_surfaces_cavity_wall[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_wall_bl_fore_bl[1]} };
bl_long_surfaces_cavity_wall[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_wall_bl_aft_bl[1]} };
bl_long_surfaces_cavity_bottom[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_bottom_bl_fore_bl[1]} };
bl_long_surfaces_cavity_bottom[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_bottom_bl_aft_bl[1]} };
bl_long_surfaces_cavity_front[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_front_bl_fore_bl[1]} };
bl_long_surfaces_cavity_front[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_front_bl_aft_bl[1]} };

box_dir = 2;
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_upper_aft_bl[1]};
Call EdgeAndSurfaces;
bl_long_surfaces_cavity_upper[] += surfaces[];

bb[] = BoundingBox Volume{cav_surf_vec_interior_upper_fore_bl[1]};
Call EdgeAndSurfaces;
bl_long_surfaces_cavity_upper[] += surfaces[];

bb[] = BoundingBox Volume{cav_surf_vec_interior_lower_aft_bl[1]};
Call EdgeAndSurfaces;
bl_long_surfaces_cavity_lower[] += surfaces[];

bb[] = BoundingBox Volume{cav_surf_vec_interior_lower_fore_bl[1]};
Call EdgeAndSurfaces;
bl_long_surfaces_cavity_lower[] += surfaces[];

bl_long_surfaces_cavity_corner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_corner_bl[1]} };
bl_long_surfaces_cavity_iso_inner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_iso_lower_bl[1]} };
bl_long_surfaces_cavity_iso_inner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_iso_upper_bl[1]} };
bl_long_surfaces_cavity_flat_inner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_flat_lower_bl[1]} };
bl_long_surfaces_cavity_flat_inner[] += Surface In BoundingBox { BoundingBox Volume{ cav_surf_vec_interior_flat_upper_bl[1]} };


Printf("bl_long_surfaces_cavity_corner length = %g", #bl_long_surfaces_cavity_corner[]);
For i In {0:#bl_long_surfaces_cavity_corner[]-1}
    Printf("bl_long_surfaces_cavity_corner: %g",bl_long_surfaces_cavity_corner[i]);
EndFor

box_dir = 0;

//////////////////
// Cavity Flat ///
//////////////////
Printf("Cavity Flat");
// fore/aft/top/bottom corners
//  aft-bottom
//  increase the tol a little to catch the cavity cube corner volumes
box_tol = 0.002;
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{flat_surf_vec_bottom_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];


//fore-bottom
edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{flat_surf_vec_bottom_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// aft-top
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{flat_surf_vec_top_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-top
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{flat_surf_vec_top_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

box_tol = 0.0001;
    
//Printf("bl_corner_vert_edges length = %g", #bl_corner_vert_edges[]);
//For i In {0:#bl_corner_vert_edges[]-1}
    //Printf("bl_corner_vert_edges: %g",bl_corner_vert_edges[i]);
//EndFor
//Printf("bl_corner_surfaces length = %g", #bl_corner_surfaces[]);
//For i In {0:#bl_corner_surfaces[]-1}
    //Printf("bl_corner_surfaces: %g",bl_corner_surfaces[i]);
//EndFor



//  fore/aft/top/bottom side planes/edges
//  we don't need the orientation information here, so just remove it so we can easily subtract the 
//  corner edges
//  bottom
//  increase the tol a little to catch the cavity corner volumes
box_tol = 0.002;
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{flat_surf_vec_interior_bottom_bl[1]};
bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_bottom_edges[] += Abs(edges[]);

// top
//edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{flat_surf_vec_interior_top_bl[1]};
bl_top_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_top_edges[] += Abs(edges[]);
bl_top_surfaces[] += surfaces[];

// aft
//edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{flat_surf_vec_interior_aft_bl[1]};
bl_aft_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_aft_edges[] += Abs(edges[]);
bl_aft_surfaces[] += surfaces[];

// fore
//edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{flat_surf_vec_interior_fore_bl[1]};
bl_fore_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_fore_edges[] += Abs(edges[]);
bl_fore_surfaces[] += surfaces[];
box_tol = 0.0001;

//
// remove the short edges from the fore/aft/top/bottom lists
//
bl_fore_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_aft_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_top_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_bottom_edges[] -= Abs(bl_corner_vert_edges[]); 

// 
// remove any misplaced corner surfaces from the fore/aft/top/bottom lists
//
bl_fore_surfaces[] -= bl_corner_surfaces[];
bl_aft_surfaces[] -= bl_corner_surfaces[];
bl_top_surfaces[] -= bl_corner_surfaces[];
bl_bottom_surfaces[] -= bl_corner_surfaces[];

//
// long side edges
// we can construct from the already discovered edges and the existing volumes
// 
bl_long_surfaces_flat[] += Surface In BoundingBox { BoundingBox Volume{ flat_surf_vec_top_bl_aft_bl[1]} };
bl_long_surfaces_flat[] += Surface In BoundingBox { BoundingBox Volume{ flat_surf_vec_bottom_bl_aft_bl[1]} };
bl_long_surfaces_flat[] += Surface In BoundingBox { BoundingBox Volume{ flat_surf_vec_top_bl_fore_bl[1]} };
bl_long_surfaces_flat[] += Surface In BoundingBox { BoundingBox Volume{ flat_surf_vec_bottom_bl_fore_bl[1]} };


// remove duplicates
bl_corner_vert_edges[] = Unique(bl_corner_vert_edges[]);
bl_corner_surfaces[] = Unique(bl_corner_surfaces[]);

bl_aft_edges[] = Unique(bl_aft_edges[]);
bl_fore_edges[] = Unique(bl_fore_edges[]);
bl_top_edges[] = Unique(bl_top_edges[]);
bl_bottom_edges[] = Unique(bl_bottom_edges[]);
bl_aft_surfaces[] = Unique(bl_aft_surfaces[]);
bl_fore_surfaces[] = Unique(bl_fore_surfaces[]);
bl_top_surfaces[] = Unique(bl_top_surfaces[]);
bl_bottom_surfaces[] = Unique(bl_bottom_surfaces[]);

//Printf("bl_aft_edges length = %g", #bl_aft_edges[]);
//For i In {0:#bl_aft_edges[]-1}
    //Printf("bl_aft_edges: %g",bl_aft_edges[i]);
//EndFor
//Printf("bl_aft_surfaces length = %g", #bl_aft_surfaces[]);
//For i In {0:#bl_aft_surfaces[]-1}
    //Printf("bl_aft_surfaces: %g",bl_aft_surfaces[i]);
//EndFor
//
//Printf("bl_fore_edges length = %g", #bl_fore_edges[]);
//Printf("bl_top_edges length = %g", #bl_top_edges[]);
//Printf("bl_bottom_edges length = %g", #bl_bottom_edges[]);


// remove the end surfaces
bl_long_surfaces_isolator[] -= bl_corner_surfaces[];
bl_long_surfaces_flat[] -= bl_corner_surfaces[];
bl_long_surfaces_cavity_top[] -= bl_corner_surfaces[];
bl_long_surfaces_cavity_wall[] -= bl_corner_surfaces[];
bl_long_surfaces_cavity_bottom[] -= bl_corner_surfaces[];
bl_long_surfaces_cavity_front[] -= bl_corner_surfaces[];


// get the edges
For i In {0:#bl_long_surfaces_isolator[]-1}
    bl_long_edges_isolator[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_isolator[i] } };
EndFor

// remove the end surfaces
bl_long_edges_isolator[] = Unique(bl_long_edges_isolator[]);
bl_long_edges_isolator[] -= Abs(bl_corner_vert_edges[]);

// get the edges
For i In {0:#bl_long_surfaces_flat[]-1}
    bl_long_edges_flat[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_flat[i] } };
EndFor

// remove the end surfaces
bl_long_edges_flat[] = Unique(bl_long_edges_flat[]);
bl_long_edges_flat[] -= Abs(bl_corner_vert_edges[]);

// get the edges
For i In {0:#bl_long_surfaces_cavity_top[]-1}
    bl_long_edges_cavity_top[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_top[i] } };
EndFor

// remove the end surfaces
bl_long_edges_cavity_top[] = Unique(bl_long_edges_cavity_top[]);
bl_long_edges_cavity_top[] -= Abs(bl_corner_vert_edges[]);



// get the edges
For i In {0:#bl_long_surfaces_cavity_inner[]-1}
    bl_long_edges_cavity_inner[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_inner[i] } };
EndFor

// remove the end surfaces
bl_long_edges_cavity_inner[] = Unique(bl_long_edges_cavity_inner[]);
bl_long_edges_cavity_inner[] -= Abs(bl_corner_vert_edges[]);

// get the edges
For i In {0:#bl_long_surfaces_cavity_wall[]-1}
    bl_long_edges_cavity_wall[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_wall[i] } };
EndFor

// remove the end surfaces
bl_long_edges_cavity_wall[] = Unique(bl_long_edges_cavity_wall[]);
bl_long_edges_cavity_wall[] -= Abs(bl_corner_vert_edges[]);

// get the edges
For i In {0:#bl_long_surfaces_cavity_bottom[]-1}
    bl_long_edges_cavity_bottom[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_bottom[i] } };
EndFor

// remove the end surfaces
bl_long_edges_cavity_bottom[] = Unique(bl_long_edges_cavity_bottom[]);
bl_long_edges_cavity_bottom[] -= Abs(bl_corner_vert_edges[]);

// get the edges
For i In {0:#bl_long_surfaces_cavity_front[]-1}
    bl_long_edges_cavity_front[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_front[i] } };
EndFor

// remove the end surfaces
bl_long_edges_cavity_front[] = Unique(bl_long_edges_cavity_front[]);
bl_long_edges_cavity_front[] -= Abs(bl_corner_vert_edges[]);

// get the edges
//For i In {0:#bl_long_surfaces_cavity_upper[]-1}
    //bl_long_edges_cavity_upper[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_upper[i] } };
//EndFor
//
// get the edges
//For i In {0:#bl_long_surfaces_cavity_lower[]-1}
    //bl_long_edges_cavity_lower[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_cavity_lower[i] } };
//EndFor

// remove the end surfaces
//bl_long_edges_cavity_upper[] = Unique(bl_long_edges_cavity_upper[]);
//bl_long_edges_cavity_upper[] -= Abs(bl_corner_vert_edges[]);
//bl_long_edges_cavity_upper[] -= bl_long_edges_cavity_flat[];
//bl_long_edges_cavity_upper[] -= bl_long_edges_cavity_top[];
//bl_long_edges_cavity_upper[] -= bl_aft_edges[];
//bl_long_edges_cavity_upper[] -= bl_fore_edges[];
//Printf("bl_long_edges_cavity_upper length = %g", #bl_long_edges_cavity_upper[]);
//For i In {0:#bl_long_edges_cavity_upper[]-1}
    //Printf("bl_long_edges_cavity_upper: %g",bl_long_edges_cavity_upper[i]);
//EndFor

//Printf("bl_long_edges length = %g", #bl_long_edges[]);
//For i In {0:#bl_long_edges[]-1}
    //Printf("bl_long_edges: %g",bl_long_edges[i]);
//EndFor
//Printf("bl_long_surfaces length = %g", #bl_long_surfaces[]);
//For i In {0:#bl_long_surfaces[]-1}
    //Printf("bl_long_surfaces: %g",bl_long_surfaces[i]);
//EndFor

//
// get the exterior surfaces of all the volumes
//
exterior_surfaces[] = CombinedBoundary { Volume {fluid_volume[]}; };
interior_surfaces[] = CombinedBoundary { 
    Volume { 
        iso_surf_vec_interior[1],
        cav_surf_vec_interior_upper_interior[1],
        cav_surf_vec_interior_lower_interior[1]
    }; 
};
//remove the inlet/outlet planes
exterior_surfaces[] -= interior_surfaces[];
//Printf("exterior_surfaces length = %g", #exterior_surfaces[]);
//For i In {0:#exterior_surfaces[]-1}
    //Printf("exterior_surfaces: %g",exterior_surfaces[i]);
//EndFor
//Printf("interior_surfaces length = %g", #interior_surfaces[]);
//For i In {0:#interior_surfaces[]-1}
    //Printf("interior_surfaces: %g",interior_surfaces[i]);
//EndFor


////////////////////
// Apply  meshing //
////////////////////
//

// injector
// 
// around injector circuference
Transfinite Curve {
    injector_edge[]
} = 12;

// along radius
Transfinite Curve {
    injector_lines_vert[]
} = 6 Using Progression .8;

// along injector length
//Transfinite Curve {
    //8, 5
//} = 100;

// inflow/outflow surfaces of the injector bl
Transfinite Surface {
    injector_surfaces[]
};

bl_points = 5;
// end edges and surfaces defining the corner bl meshes, fore/aft/top/bottom on the inlet/outlet planes
Transfinite Curve {
    bl_corner_vert_edges[]
//} = bl_points*scale_fac_bl Using Progression 1.2;
} = bl_points*scale_fac_bl;

Transfinite Surface {
    bl_corner_surfaces[]
};

// end edges defining the fore and aft bl meshes,
Transfinite Curve {
    bl_fore_edges[],
    bl_aft_edges[]
//} = 12*scale_fac Using Bump 0.35;
} = 12*scale_fac;

Transfinite Surface {
    bl_aft_surfaces[],
    bl_fore_surfaces[]
};

// end edges defining the top and bottom bl meshes,
Transfinite Curve {
    bl_bottom_edges[],
    bl_top_edges[]
//} = 35 Using Bump 0.35;
//} = 32 Using Bump 0.35;
//} = 16*scale_fac Using Bump 0.35;
} = 16*scale_fac;
//} = 35;

Transfinite Surface {
    bl_bottom_surfaces[],
    bl_top_surfaces[]
};


Transfinite Curve {
    bl_long_edges_isolator[]
} = 10*scale_fac;

Transfinite Curve {
    bl_long_edges_flat[]
} = 18*scale_fac;

Transfinite Curve {
    bl_long_edges_cavity_top[],
    bl_long_edges_cavity_inner[],
    bl_long_edges_cavity_bottom[]
} = 38*scale_fac;

Transfinite Curve {
    bl_long_edges_cavity_wall[],
    bl_long_edges_cavity_front[]
} = 18*scale_fac;

Transfinite Surface {
    bl_long_surfaces_isolator[],
    bl_long_surfaces_flat[],
    bl_long_surfaces_cavity_top[],
    bl_long_surfaces_cavity_wall[],
    bl_long_surfaces_cavity_bottom[],
    bl_long_surfaces_cavity_front[],
    bl_long_surfaces_cavity_inner[],
    bl_long_surfaces_cavity_iso_inner[],
    bl_long_surfaces_cavity_flat_inner[],
    bl_long_surfaces_cavity_corner[],
    bl_long_surfaces_cavity_upper[],
    bl_long_surfaces_cavity_lower[]
};


Transfinite Volume{
    iso_surf_vec_top_bl_aft_bl[1],
    iso_surf_vec_bottom_bl_aft_bl[1],
    iso_surf_vec_top_bl_fore_bl[1],
    iso_surf_vec_bottom_bl_fore_bl[1],
    iso_surf_vec_interior_top_bl[1],
    iso_surf_vec_interior_bottom_bl[1],
    iso_surf_vec_interior_aft_bl[1],
    iso_surf_vec_interior_fore_bl[1]
};

Transfinite Volume{
    flat_surf_vec_top_bl_aft_bl[1],
    flat_surf_vec_bottom_bl_aft_bl[1],
    flat_surf_vec_top_bl_fore_bl[1],
    flat_surf_vec_bottom_bl_fore_bl[1],
    flat_surf_vec_interior_top_bl[1],
    flat_surf_vec_interior_bottom_bl[1],
    flat_surf_vec_interior_aft_bl[1],
    flat_surf_vec_interior_fore_bl[1]
};

Transfinite Volume{
    cav_surf_vec_top_bl_aft_bl[1],
    cav_surf_vec_interior_upper_aft_bl[1],
    cav_surf_vec_interior_lower_aft_bl[1],
    cav_surf_vec_front_bl_aft_bl[1] ,
    cav_surf_vec_bottom_bl_aft_bl[1],
    cav_surf_vec_wall_bl_aft_bl[1],
    cav_surf_vec_interior_aft_bl[1],
    cav_surf_vec_iso_lower_bl_aft_bl[1],
    cav_surf_vec_corner_bl_aft_bl[1],
    cav_surf_vec_iso_upper_bl_aft_bl[1],
    cav_surf_vec_flat_lower_bl_aft_bl[1],
    cav_surf_vec_flat_upper_bl_aft_bl[1],
    cav_surf_vec_front_upper_bl_aft_bl[1],
    cav_surf_vec_rear_upper_bl_aft_bl[1],
    // cavity fore-aft interior
    cav_surf_vec_interior_top_bl[1],
    cav_surf_vec_interior_front_bl[1],
    cav_surf_vec_interior_bottom_bl[1],
    //cav_surf_vec_interior_wall_bl[1],
    cav_surf_vec_interior_iso_lower_bl[1],
    cav_surf_vec_interior_corner_bl[1],
    cav_surf_vec_interior_iso_upper_bl[1],
    cav_surf_vec_interior_flat_lower_bl[1],
    cav_surf_vec_interior_flat_upper_bl[1],
    //cav_surf_vec_interior_front_upper_bl[1],
    //cav_surf_vec_interior_rear_upper_bl[1],
    // cavity fore bl
    cav_surf_vec_top_bl_fore_bl[1],
    cav_surf_vec_interior_upper_fore_bl[1],
    cav_surf_vec_interior_lower_fore_bl[1],
    cav_surf_vec_front_bl_fore_bl[1],
    cav_surf_vec_bottom_bl_fore_bl[1],
    cav_surf_vec_wall_bl_fore_bl[1],
    cav_surf_vec_interior_fore_bl[1],
    cav_surf_vec_iso_lower_bl_fore_bl[1],
    cav_surf_vec_corner_bl_fore_bl[1],
    cav_surf_vec_iso_upper_bl_fore_bl[1],
    cav_surf_vec_flat_lower_bl_fore_bl[1],
    cav_surf_vec_flat_upper_bl_fore_bl[1],
    cav_surf_vec_front_upper_bl_fore_bl[1],
    cav_surf_vec_rear_upper_bl_fore_bl[1]
};


// fine the interior surfaces for refinement
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_upper_interior[1]};
cav_upper_interior_surfaces[] = Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
cav_upper_interior_surfaces[] -= surfaces[];

// fine the interior surfaces for refinement
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{cav_surf_vec_interior_lower_interior[1]};
cav_lower_interior_surfaces[] = Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
cav_lower_interior_surfaces[] -= surfaces[];

Printf("cav_lower_interior_surfaces length = %g", #cav_lower_interior_surfaces[]);
For i In {0:#cav_lower_interior_surfaces[]-1}
    Printf("cav_lower_interior_surfaces: %g",cav_lower_interior_surfaces[i]);
EndFor

// Create distance field from surfaces for wall meshing, excludes cavity, injector
Field[1] = Distance;
Field[1].SurfacesList = {
    cav_upper_interior_surfaces[]
};
Field[1].Sampling = 1000;
//
//Create threshold field that varrries element size near boundaries
Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = isosize / boundratio;
Field[2].SizeMax = isosize;
Field[2].DistMin = 0.000001;
Field[2].DistMax = 0.005;
//Field[2].DistMax = 0.0015;
Field[2].StopAtDistMax = 1;

// Create distance field from curves, cavity only
Field[11] = Distance;
Field[11].SurfacesList = {
    cav_lower_interior_surfaces[]
};
Field[11].Sampling = 1000;

//Create threshold field that varrries element size near boundaries
Field[12] = Threshold;
Field[12].InField = 11;
Field[12].SizeMin = cavitysize / boundratiocavity;
Field[12].SizeMax = cavitysize;
Field[12].DistMin = 0.000001;
Field[12].DistMax = 0.01;
Field[12].StopAtDistMax = 1;

//  background mesh size in the isolator (downstream of the nozzle)
Field[3] = Box;
Field[3].XMin = nozzle_end;
Field[3].XMax = 1.0;
Field[3].YMin = -1.0;
Field[3].YMax = 1.0;
Field[3].ZMin = -1.0;
Field[3].ZMax = 1.0;
Field[3].VIn = isosize;
Field[3].VOut = bigsize;

// background mesh size upstream of the inlet
Field[4] = Box;
Field[4].XMin = 0.;
Field[4].XMax = nozzle_start;
Field[4].YMin = -1.0;
Field[4].YMax = 1.0;
Field[4].ZMin = -1.0;
Field[4].ZMax = 1.0;
Field[4].VIn = inletsize;
Field[4].VOut = bigsize;

// background mesh size in the nozzle throat
Field[5] = Box;
Field[5].XMin = nozzle_start;
Field[5].XMax = nozzle_end;
Field[5].YMin = -1.0;
Field[5].YMax = 1.0;
Field[5].ZMin = -1.0;
Field[5].ZMax = 1.0;
Field[5].Thickness = 0.10;    // interpolate from VIn to Vout over a distance around the box
Field[5].VIn = nozzlesize;
Field[5].VOut = bigsize;

// background mesh size in the cavity region
cavity_start = 0.65;
cavity_end = 0.73;
Field[6] = Box;
Field[6].XMin = cavity_start;
Field[6].XMax = cavity_end;
Field[6].YMin = -1.0;
//Field[6].YMax = -0.003;
Field[6].YMax = 0.0;
Field[6].ZMin = -1.0;
Field[6].ZMax = 1.0;
Field[6].Thickness = 0.10;    // interpolate from VIn to Vout over a distance around the box
Field[6].VIn = cavitysize;
Field[6].VOut = bigsize;

// background mesh size in the injection region
injector_start_x = 0.69;
injector_end_x = 0.75;
//injector_start_y = -0.0225;
injector_start_y = -0.021;
injector_end_y = -0.026;
injector_start_z = 0.0175 - 0.002;
injector_end_z = 0.0175 + 0.002;
Field[7] = Box;
Field[7].XMin = injector_start_x;
Field[7].XMax = injector_end_x;
Field[7].YMin = injector_start_y;
Field[7].YMax = injector_end_y;
Field[7].ZMin = injector_start_z;
Field[7].ZMax = injector_end_z;
Field[7].Thickness = 0.10;    // interpolate from VIn to Vout over a distance around the cylinder
Field[7].VIn = injectorsize;
Field[7].VOut = bigsize;

// background mesh size in the shear region
shear_start_x = 0.65;
shear_end_x = 0.75;
shear_start_y = -0.004;
shear_end_y = -0.01;
Field[8] = Box;
Field[8].XMin = shear_start_x;
Field[8].XMax = shear_end_x;
Field[8].YMin = shear_start_y;
Field[8].YMax = shear_end_y;
Field[8].ZMin = -1.0;
Field[8].ZMax = 1.0;
Field[8].Thickness = 0.10;
Field[8].VIn = shearsize;
Field[8].VOut = bigsize;

// take the minimum of all defined meshing fields
//
Field[100] = Min;
//Field[100].FieldsList = {2, 3, 4, 5, 6, 7, 8, 12, 14};
Field[100].FieldsList = {2, 3, 4, 5, 6, 7, 8, 12};
Background Field = 100;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;


// Delaunay, seems to respect changing mesh sizes better
// Mesh.Algorithm3D = 1; 
// Frontal, makes a better looking mesh, will make bigger elements where I don't want them though
// Doesn't repsect the mesh sizing parameters ...
//Mesh.Algorithm3D = 4; 
// HXT, re-implemented Delaunay in parallel
Mesh.Algorithm3D = 10; 
//Mesh.OptimizeNetgen = 1;
//Mesh.Smoothing = 100;
