#!/bin/bash
NCPUS=$(getconf _NPROCESSORS_ONLN)
gmsh -setnumber size 0.0032 -setnumber blratio 4 -setnumber cavityfac 4 -setnumber isofac 2 -setnumber blratiocavity 2 -setnumber blratioinjector 1 -setnumber injectorfac 6 -setnumber shearfac 3 -o isolator.msh -nopopup -format msh2 ./isolator.geo -2 -nt $NCPUS
