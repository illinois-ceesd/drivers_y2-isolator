#!/bin/bash


NCPUS=$(getconf _NPROCESSORS_ONLN)

#gmsh -setnumber size 0.0064 -setnumber blratio 4 -setnumber cavityfac 4 -setnumber isofac 2 -setnumber blratiocavity 2 -setnumber blratioinjector 2 -setnumber injectorfac 4 -setnumber shearfac 4 -o isolator.msh -nopopup -format msh2 ./isolator_full.geo -3 -nt $NCPUS
gmsh -setnumber scale 2 -setnumber scale_bl 1 -setnumber blratio 2 -setnumber isofac 2 -o isolator.msh -nopopup -format msh2 ./combustor.geo -3 -nt $NCPUS
