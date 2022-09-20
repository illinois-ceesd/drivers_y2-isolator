#!/bin/bash


NCPUS=$(getconf _NPROCESSORS_ONLN)

#gmsh -setnumber size 0.0064 -setnumber blratio 4 -setnumber cavityfac 4 -setnumber isofac 2 -setnumber blratiocavity 2 -setnumber blratioinjector 2 -setnumber injectorfac 4 -setnumber shearfac 4 -o isolator.msh -nopopup -format msh2 ./isolator_full.geo -3 -nt $NCPUS
gmsh -setnumber blratio 2 -setnumber cavityfac 4 -setnumber isofac 2 -setnumber blratiocavity 2 -setnumber blratioinjector 2 -setnumber injectorfac 5 -setnumber shearfac 3 -setnumber scale 1 -setnumber scale_bl 1 -o isolator.msh -nopopup -format msh2 ./isolator_full.geo -3 -nt $NCPUS
