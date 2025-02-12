# -*- coding: utf-8 -*-

###
### This file is generated automatically by SALOME v7.5.1 with dump python functionality
###

import sys
import salome

salome.salome_init()
theStudy = salome.myStudy

import salome_notebook
notebook = salome_notebook.NoteBook(theStudy)
sys.path.insert( 0, r'/home/shorty/OpenFOAM/shorty-2.3.1/run/meshing/90DegreePipe/cad')

###
### GEOM component
###

import GEOM
from salome.geom import geomBuilder
import math
import SALOMEDS


geompy = geomBuilder.New(theStudy)

O = geompy.MakeVertex(0, 0, 0)
OX = geompy.MakeVectorDXDYDZ(1, 0, 0)
OY = geompy.MakeVectorDXDYDZ(0, 1, 0)
OZ = geompy.MakeVectorDXDYDZ(0, 0, 1)
Cylinder_1 = geompy.MakeCylinderRH(0.02, 0.2)
[Face_1] = geompy.SubShapes(Cylinder_1, [10])
Vertex_1 = geompy.MakeVertex(0.04, -0, 0.2)
Vertex_2 = geompy.MakeVertex(0.04, 0.02, 0.2)
Line_1 = geompy.MakeLineTwoPnt(Vertex_2, Vertex_1)
Revolution_1 = geompy.MakeRevolution(Face_1, Line_1, -90*math.pi/180.0)
[Face_2] = geompy.SubShapes(Revolution_1, [12])
Extrusion_1 = geompy.MakePrismVecH(Face_2, OX, 0.2)
pipe = geompy.MakeFuseList([Cylinder_1, Revolution_1, Extrusion_1], True, True)
inlet = geompy.CreateGroup(pipe, geompy.ShapeType["FACE"])
geompy.UnionIDs(inlet, [15])
outlet = geompy.CreateGroup(pipe, geompy.ShapeType["FACE"])
geompy.UnionIDs(outlet, [22])
wall = geompy.CreateGroup(pipe, geompy.ShapeType["FACE"])
geompy.UnionIDs(wall, [10, 3, 17])
Bounding_Box_1 = geompy.MakeBoundingBox(pipe, True)
geomObj_1 = geompy.MakeCDG(Bounding_Box_1)
Point_1 = geompy.MakeCDG(Bounding_Box_1)
bgMesh = geompy.MakeScaleTransform(Bounding_Box_1, Point_1, 2)
geompy.addToStudy( O, 'O' )
geompy.addToStudy( OX, 'OX' )
geompy.addToStudy( OY, 'OY' )
geompy.addToStudy( OZ, 'OZ' )
geompy.addToStudy( Cylinder_1, 'Cylinder_1' )
geompy.addToStudy( Vertex_1, 'Vertex_1' )
geompy.addToStudyInFather( Cylinder_1, Face_1, 'Face_1' )
geompy.addToStudy( Vertex_2, 'Vertex_2' )
geompy.addToStudy( Line_1, 'Line_1' )
geompy.addToStudy( Revolution_1, 'Revolution_1' )
geompy.addToStudyInFather( Revolution_1, Face_2, 'Face_2' )
geompy.addToStudy( Extrusion_1, 'Extrusion_1' )
geompy.addToStudy( pipe, 'pipe' )
geompy.addToStudyInFather( pipe, inlet, 'inlet' )
geompy.addToStudyInFather( pipe, outlet, 'outlet' )
geompy.addToStudyInFather( pipe, wall, 'wall' )
geompy.addToStudy( Bounding_Box_1, 'Bounding Box_1' )
geompy.addToStudy( Point_1, 'Point_1' )
geompy.addToStudy( bgMesh, 'bgMesh' )

###
### SMESH component
###

import  SMESH, SALOMEDS
from salome.smesh import smeshBuilder

smesh = smeshBuilder.New(theStudy)
inlet_1 = smesh.Mesh(inlet)
Regular_1D = inlet_1.Segment()
Local_Length_1 = Regular_1D.LocalLength(0.002,[],1e-07)
NETGEN_2D_ONLY = inlet_1.Triangle(algo=smeshBuilder.NETGEN_2D)
isDone = inlet_1.Compute()
outlet_1 = smesh.Mesh(outlet)
status = outlet_1.AddHypothesis(Local_Length_1)
status = outlet_1.AddHypothesis(Regular_1D)
status = outlet_1.AddHypothesis(NETGEN_2D_ONLY)
isDone = outlet_1.Compute()
wall_1 = smesh.Mesh(wall)
status = wall_1.AddHypothesis(Local_Length_1)
status = wall_1.AddHypothesis(Regular_1D)
status = wall_1.AddHypothesis(NETGEN_2D_ONLY)
isDone = wall_1.Compute()
wall_1.ExportSTL( r'/home/shorty/OpenFOAM/shorty-2.3.1/run/meshing/90DegreePipe/cad/stl/wall.stl', 1 )
outlet_1.ExportSTL( r'/home/shorty/OpenFOAM/shorty-2.3.1/run/meshing/90DegreePipe/cad/stl/outlet.stl', 1 )
inlet_1.ExportSTL( r'/home/shorty/OpenFOAM/shorty-2.3.1/run/meshing/90DegreePipe/cad/stl/inlet.stl', 1 )
Local_Length_2 = smesh.CreateHypothesis('LocalLength')
bgMesh_1 = smesh.Mesh(bgMesh)
status = bgMesh_1.AddHypothesis(Local_Length_2)
status = bgMesh_1.AddHypothesis(Regular_1D)
Quadrangle_2D = bgMesh_1.Quadrangle(algo=smeshBuilder.QUADRANGLE)
Hexa_3D = bgMesh_1.Hexahedron(algo=smeshBuilder.Hexa)
Local_Length_2.SetLength( 0.005 )
Local_Length_2.SetPrecision( 1e-07 )
isDone = bgMesh_1.Compute()
bgMesh_1.ExportUNV( r'/home/shorty/OpenFOAM/shorty-2.3.1/run/meshing/90DegreePipe/cad/backgroundMesh.unv' )


## Set names of Mesh objects
smesh.SetName(Regular_1D.GetAlgorithm(), 'Regular_1D')
smesh.SetName(Quadrangle_2D.GetAlgorithm(), 'Quadrangle_2D')
smesh.SetName(NETGEN_2D_ONLY.GetAlgorithm(), 'NETGEN_2D_ONLY')
smesh.SetName(Hexa_3D.GetAlgorithm(), 'Hexa_3D')
smesh.SetName(Local_Length_2, 'Local Length_2')
smesh.SetName(Local_Length_1, 'Local Length_1')
smesh.SetName(inlet_1.GetMesh(), 'inlet')
smesh.SetName(wall_1.GetMesh(), 'wall')
smesh.SetName(outlet_1.GetMesh(), 'outlet')
smesh.SetName(bgMesh_1.GetMesh(), 'bgMesh')


if salome.sg.hasDesktop():
  salome.sg.updateObjBrowser(1)
