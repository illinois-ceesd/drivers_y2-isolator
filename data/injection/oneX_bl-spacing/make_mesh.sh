#!/bin/bash
gmsh -setnumber size 0.0008 -setnumber blratio 4 -setnumber blratiocavity 2 -setnumber blratioinjector 4 -setnumber injectorfac 20 -o isolator.msh -nopopup -format msh2 ./isolator.geo -2
