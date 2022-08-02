#!/bin/bash
NCPUS=$(getconf _NPROCESSORS_ONLN)
gmsh -setnumber size 0.0016 -setnumber blratio 4 -setnumber cavityfac 4 -setnumber isofac 2 -setnumber blratiocavity 2 -setnumber blratioinjector 2 -setnumber injectorfac 10 -setnumber shearfac 4 -o isolator.msh -nopopup -format msh2 ./isolator.geo -2 -nt $NCPUS
