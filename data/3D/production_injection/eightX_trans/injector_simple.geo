SetFactory("OpenCASCADE");
//Geometry.CopyMeshingMethod = 1;

If(Exists(size))
    basesize=size;
Else
    basesize=0.0064;
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
    injector_factor=8;
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

p = 1;
l = 1;
s = 1;

//
// injector geometry
//
bl_thickness_inj = 0.00025;
Cylinder(3000) =  {0.70163, -0.0283245 + inj_h + inj_t/2., 0.035/2., inj_d, 0.0, 0.0, inj_t/2.0, Pi };
//Cylinder(3001) =  {0.70163, -0.0283245 + inj_h + inj_t/2., 0.035/2., inj_d, 0.0, 0.0, inj_t/2.0, Pi };
tmp[] = Symmetry { 0, -1, 0, -0.0283245 + inj_h + inj_t/2.} {Duplicata{Volume{3000};}};
Cylinder(3002) = {0.70163, -0.0283245 + inj_h + inj_t/2., 0.035/2., inj_d, 0.0, 0.0, inj_t/2.0-bl_thickness_inj, 2*Pi };
//injector_bl[] = Extrude {0,0,bl_thickness_inj} { Surface{1}; Layers{10}; };
//tmp[] = Extrude {
  //Surface{1}; Layers{5, 0.2}; Recombine; // 14:28:2 means itterate from 14 to 28 by steps of 2
//};

// subtract the boundary layer volume
injector_bl1[] = BooleanDifference {
    Volume{3000}; Delete; } {
    Volume{3002}; };
// subtract the boundary layer volume
injector_bl2[] = BooleanDifference {
    Volume{tmp[0]}; Delete; } {
    Volume{3002}; };

Coherence; // remove duplicate entities

box_tol = 0.0001;
//inlet_face_lines[] = Curve in BoundingBox {xmin, ymin, zmin, xmax, ymax, zmax};
inlet_lines[] = Curve In BoundingBox {
    .70163 - box_tol, -0.0283245 +inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + box_tol, -0.0283245 +inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
inlet_lines[] += Curve In BoundingBox {
    .70163 + inj_d - box_tol, -0.0283245 +inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_d + box_tol, -0.0283245 +inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
Printf("inlet_lines length = %g", #inlet_lines[]);
For i In {0:#inlet_lines[]-1}
    Printf("inlet_lines: %g",inlet_lines[i]);
EndFor

inlet_lines_vert[] = Curve In BoundingBox {
    .70163 - box_tol, -0.0283245 +inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + box_tol, -0.0283245 +inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
inlet_lines_vert[] += Curve In BoundingBox {
    .70163 +inj_d - box_tol, -0.0283245 +inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 +inj_d + box_tol, -0.0283245 +inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
Printf("inlet_lines_vert length = %g", #inlet_lines_vert[]);
For i In {0:#inlet_lines_vert[]-1}
    Printf("inlet_lines_vert: %g",inlet_lines_vert[i]);
EndFor

// remove the verical lines from the inlet face
For i In {0:#inlet_lines[]-1}
    id1 = inlet_lines[i];
    inList = 0;
    For j In {0:#inlet_lines_vert[]-1}
        id2 = inlet_lines_vert[j];
        If (id1 == id2)
            inList = 1;
        EndIf
    EndFor
    If (inList == 0)
        Printf("unique line: %g",id1);
        unique_list[] += id1;
    EndIf
EndFor

Printf("unique_list length = %g", #unique_list[]);
For i In {0:#unique_list[]-1}
    Printf("unique_list: %g",unique_list[i]);
EndFor

inlet_surfaces[] = Surface In BoundingBox {
    .70163 - box_tol, -0.0283245 + inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + box_tol, -0.0283245 + inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
inlet_surfaces[] += Surface In BoundingBox {
    .70163 - box_tol, -0.0283245 + inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + box_tol, -0.0283245 + inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
inlet_surfaces[] += Surface In BoundingBox {
    .70163 + inj_d - box_tol, -0.0283245 + inj_h - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_d + box_tol, -0.0283245 + inj_h + inj_t/2. + box_tol, 0.035/2. + inj_t/2. + box_tol
};
inlet_surfaces[] += Surface In BoundingBox {
    .70163 + inj_d - box_tol, -0.0283245 + inj_h + inj_t/2. - box_tol, 0.035/2. - inj_t/2. - box_tol,
    .70163 + inj_d + box_tol, -0.0283245 + inj_h + inj_t + box_tol, 0.035/2. + inj_t/2. + box_tol
};
Printf("inlet_surfaces length = %g", #inlet_surfaces[]);
For i In {0:#inlet_surfaces[]-1}
    Printf("inlet_surfaces: %g",inlet_surfaces[i]);
EndFor


// setup structured bl meshes
// around injector circuference
Transfinite Curve {
    //1, 3, 13, 14,
    //11, 16, 6, 15
    unique_list[]
} = 12;

// along radius
Transfinite Curve {
    //8, 10, 5, 7
    inlet_lines_vert[]
} = 6 Using Progression .8;

// along injector length
//Transfinite Curve {
    //8, 5
//} = 100;

// inflow/outflow surfaces of the injector bl
Transfinite Surface {
    inlet_surfaces[]
    //4, 9, 2, 8
};

//// injector bl walls
//Transfinite Surface {
    //4, 7
//};


// background mesh size for the injector
injector_start = 0.69;
injector_end = 0.75;
injector_bottom = -1;
injector_top = 1;
Field[7] = Box;
Field[7].XMin = injector_start;
Field[7].XMax = injector_end;
Field[7].YMin = injector_bottom;
Field[7].YMax = injector_top;
Field[7].ZMin = injector_bottom;
Field[7].ZMax = injector_top;
Field[7].Thickness = 0.10;    // interpolate from VIn to Vout over a distance around the box
Field[7].VIn = injectorsize;
Field[7].VOut = bigsize;
// take the minimum of all defined meshing fields
//
Field[100] = Min;
Field[100].FieldsList = {7};
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
