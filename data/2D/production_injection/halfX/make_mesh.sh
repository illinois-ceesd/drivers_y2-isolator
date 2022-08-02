#!/bin/bash
NCPUS=$(getconf _NPROCESSORS_ONLN)
gmsh -setnumber size 0.0016 -setnumber blratio 4 -setnumber cavityfac 4 -setnumber isofac 2 -setnumber blratiocavity 2 -setnumber blratioinjector 2 -setnumber injectorfac 10 -setnumber shearfac 4 -o isolator.msh -nopopup -format msh2 ./isolator.geo -2 -nt $NCPUS
#gmsh -setnumber size 0.0016 -setnumber blratio 1 -setnumber cavityfac 1 -setnumber isofac 1 -setnumber blratiocavity 1 -setnumber blratioinjector 1 -setnumber injectorfac 1 -setnumber shearfac 2 -o isolator.msh -nopopup -format msh2 ./isolator.geo -2 -nt $NCPUS
