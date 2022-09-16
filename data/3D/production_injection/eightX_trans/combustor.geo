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
    boundratio=2.0;
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
nozzlesize = basesize/12;       // background mesh size in the nozzle
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

bl_thickness = 0.0015;
y_isolator_top = 0.01167548819733;
y_isolator_bottom = -0.0083245;
x_end = 0.65163+0.335;
y_end_bottom = y_isolator_bottom-(0.265-0.02)*Sin(2*Pi/180);
x_cavity_rl = 0.70163;
x_cavity_ru = x_cavity_rl + 0.02;

// flat bl coordinates
p_cavity_expansion_start_top = p++;
p_cavity_expansion_start_bottom = p++;
p_cavity_expansion_start_top_bl = p++;
p_cavity_expansion_start_bottom_bl = p++;
Point(p_cavity_expansion_start_bottom) = {x_cavity_ru+0.02,y_isolator_bottom,0.0,basesize};
Point(p_cavity_expansion_start_bottom_bl) = {x_cavity_ru+0.02,y_isolator_bottom+bl_thickness,0.0,basesize};
Point(p_cavity_expansion_start_top) = {x_cavity_ru+0.02,y_isolator_top,0.0,basesize};
Point(p_cavity_expansion_start_top_bl) = {x_cavity_ru+0.02,y_isolator_top-bl_thickness,0.0,basesize};

// vertical lines
l_cavity_flat_end = l++;
l_cavity_flat_bl_bottom_end = l++;
l_cavity_flat_bl_top_end = l++;

Line(l_cavity_flat_end) = {p_cavity_expansion_start_bottom_bl, p_cavity_expansion_start_top_bl};
Line(l_cavity_flat_bl_bottom_end) = {p_cavity_expansion_start_bottom, p_cavity_expansion_start_bottom_bl};
Line(l_cavity_flat_bl_top_end) = {p_cavity_expansion_start_top_bl, p_cavity_expansion_start_top};

/////////////////////
// combustor geometry
/////////////////////

p=800;
p_outlet_bottom = p++;
p_outlet_bottom_bl = p++;
p_outlet_top_bl = p++;
p_outlet_top = p++;
x_end = 0.65163+0.335;
y_end_bottom = y_isolator_bottom-(0.265-0.02)*Sin(2*Pi/180);
Point(p_outlet_bottom) = {x_end,y_end_bottom,0.0,basesize};
Point(p_outlet_bottom_bl) = {x_end,y_end_bottom+bl_thickness,0.0,basesize};
Point(p_outlet_top_bl) = {x_end,y_isolator_top-bl_thickness,0.0,basesize};
Point(p_outlet_top) = {x_end,y_isolator_top,0.0,basesize};

l_combustor_bottom = l++;
l_combustor_top = l++;
l_combustor_bl_bottom = l++;
l_combustor_bl_top = l++;
l_combustor_bl_bottom_end = l++;
l_combustor_bl_top_end = l++;
l_combustor_end = l++;
l_combustor_interior_bottom = l++;
Line(l_combustor_bottom) = {p_cavity_expansion_start_bottom,p_outlet_bottom};
Line(l_combustor_top) = {p_cavity_expansion_start_top,p_outlet_top};
Line(l_combustor_bl_bottom) = {p_cavity_expansion_start_bottom_bl,p_outlet_bottom_bl};
Line(l_combustor_bl_top) = {p_cavity_expansion_start_top_bl,p_outlet_top_bl};
Line(l_combustor_bl_bottom_end) = {p_outlet_bottom,p_outlet_bottom_bl};
Line(l_combustor_end) = {p_outlet_bottom_bl,p_outlet_top_bl};
Line(l_combustor_bl_top_end) = {p_outlet_top_bl, p_outlet_top};

//Create lineloop of this geometry
// start on the bottom left and go around clockwise
Curve Loop(2700) = { 
    l_cavity_flat_bl_top_end,
    l_combustor_top,
    -l_combustor_bl_top_end,
    -l_combustor_bl_top
}; 
Plane Surface(2700) = {2700}; // the back wall top bl

Curve Loop(2800) = { 
    l_cavity_flat_bl_bottom_end,
    l_combustor_bl_bottom,
    -l_combustor_bl_bottom_end,
    -l_combustor_bottom
}; 
Plane Surface(2800) = {2800}; // the back wall bottom bl

Curve Loop(2900) = { 
    l_cavity_flat_end,
    l_combustor_bl_top,
    -l_combustor_end,
    -l_combustor_bl_bottom
}; 
Plane Surface(2900) = {2900}; // the back wall interior



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
// combustor geometry
/////////////////////

// combustor aft bl
comb_surf_vec_top_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2700}; };
comb_surf_vec_bottom_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2800}; };
comb_surf_vec_interior_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{2900}; };

// combustor fore-aft interior
comb_surf_vec_interior_top_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{comb_surf_vec_top_bl_aft_bl[0]};};
comb_surf_vec_interior_bottom_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{comb_surf_vec_bottom_bl_aft_bl[0]};};
comb_surf_vec_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{comb_surf_vec_interior_aft_bl[0]};};

// combustor fore bl
comb_surf_vec_top_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{comb_surf_vec_interior_top_bl[0]};};
comb_surf_vec_bottom_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{comb_surf_vec_interior_bottom_bl[0]};};
comb_surf_vec_interior_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{comb_surf_vec_interior[0]};};

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

////////////////
// Combustor ///
////////////////
Printf("Combustor");
// fore/aft/top/bottom corners
//  aft-bottom
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{comb_surf_vec_bottom_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

//fore-bottom
edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{comb_surf_vec_bottom_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// aft-top
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{comb_surf_vec_top_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-top
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{comb_surf_vec_top_bl_fore_bl[1]};
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
//  bottom
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{comb_surf_vec_interior_bottom_bl[1]};
bl_bottom_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_bottom_edges[] += Abs(edges[]);

// top
//edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{comb_surf_vec_interior_top_bl[1]};
bl_top_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_top_edges[] += Abs(edges[]);

// aft
//edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{comb_surf_vec_interior_aft_bl[1]};
bl_aft_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_aft_edges[] += Abs(edges[]);

// fore
//edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{comb_surf_vec_interior_fore_bl[1]};
bl_fore_surfaces[] += Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
bl_fore_edges[] += Abs(edges[]);

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
bl_long_surfaces_combustor[] += Surface In BoundingBox { BoundingBox Volume{ comb_surf_vec_top_bl_aft_bl[1]} };
bl_long_surfaces_combustor[] += Surface In BoundingBox { BoundingBox Volume{ comb_surf_vec_bottom_bl_aft_bl[1]} };
bl_long_surfaces_combustor[] += Surface In BoundingBox { BoundingBox Volume{ comb_surf_vec_top_bl_fore_bl[1]} };
bl_long_surfaces_combustor[] += Surface In BoundingBox { BoundingBox Volume{ comb_surf_vec_bottom_bl_fore_bl[1]} };

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
bl_long_surfaces_combustor[] -= bl_corner_surfaces[];


// get the edges
For i In {0:#bl_long_surfaces_combustor[]-1}
    bl_long_edges_combustor[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces_combustor[i] } };
EndFor

// remove the end surfaces
bl_long_edges_combustor[] = Unique(bl_long_edges_combustor[]);
bl_long_edges_combustor[] -= Abs(bl_corner_vert_edges[]);

//
// get the exterior surfaces of all the volumes
//
exterior_surfaces[] = CombinedBoundary { Volume {fluid_volume[]}; };
interior_surfaces[] = CombinedBoundary { 
    Volume { 
        comb_surf_vec_interior[1]
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

// outlet surfaces
combustor_outlet_surfaces[] = Surface In BoundingBox {
    x_end - box_tol, -1., -1.,
    x_end + box_tol, 1., 1. 
};

exterior_surfaces[] -= combustor_outlet_surfaces[];
exterior_surfaces[] -= -1*combustor_outlet_surfaces[];

Physical Surface('wall') = {
    exterior_surfaces[]
};

////////////////////
// Apply  meshing //
////////////////////
//

bl_points = 5*scale_fac_bl;
// end edges and surfaces defining the corner bl meshes, fore/aft/top/bottom on the inlet/outlet planes
Transfinite Curve {
    bl_corner_vert_edges[]
//} = 7 Using Progression 1.2;
} = bl_points Using Progression 1.2;
//} = 10;

Transfinite Surface {
    bl_corner_surfaces[]
};

// end edges defining the fore and aft bl meshes,
Transfinite Curve {
    bl_fore_edges[],
    bl_aft_edges[]
//} = 12*scale_fac Using Bump 0.35;
} = 12*scale_fac Using Bump 0.35;

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
} = 16*scale_fac Using Bump 0.35;
//} = 35;

Transfinite Surface {
    bl_bottom_surfaces[],
    bl_top_surfaces[]
};

// side edges defining the x-direction spacing for each volume
Transfinite Curve {
    bl_long_edges_combustor[]
//} = 100*scale_fac Using Progression 1.005;
} = 100*scale_fac;

Transfinite Surface {
    bl_long_surfaces_combustor[]
};

Transfinite Volume{
    comb_surf_vec_top_bl_aft_bl[1],
    comb_surf_vec_bottom_bl_aft_bl[1],
    comb_surf_vec_top_bl_fore_bl[1],
    comb_surf_vec_bottom_bl_fore_bl[1],
    comb_surf_vec_interior_top_bl[1],
    comb_surf_vec_interior_bottom_bl[1],
    comb_surf_vec_interior_aft_bl[1],
    comb_surf_vec_interior_fore_bl[1]
};


// fine the interior surfaces for refinement
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{comb_surf_vec_interior[1]};
comb_interior_surfaces[] = Surface In BoundingBox { bb[] };
Call EdgeAndSurfaces;
comb_interior_surfaces[] -= surfaces[];

nozzle_start = 0.27;
nozzle_end = 0.30;

// Create distance field from surfaces for wall meshing, excludes cavity, injector
Field[1] = Distance;
Field[1].SurfacesList = {
    comb_interior_surfaces[]
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

// take the minimum of all defined meshing fields
//
Field[100] = Min;
//Field[100].FieldsList = {2, 3, 4, 5, 6, 7, 8, 12, 14};
//Field[100].FieldsList = {2, 3, 4, 5, 6, 7, 8, 12};
Field[100].FieldsList = {2, 3};
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
