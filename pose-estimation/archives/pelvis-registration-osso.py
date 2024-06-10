import trimesh
import os
import numpy as np
import sys
import ast
import json
import re

# Read arguments
osso_folder = sys.argv[1]
osso_posed_file = sys.argv[2]
registration_folder = sys.argv[3]

# Output path for registered osso
output_path = osso_folder
# Input path for posed osso
posed_path = osso_posed_file
# Case name and path
case_name = posed_path.split("/")[-1]
case_name = case_name.split(".")[0]
case_base = case_name[0:len(case_name)-11]
case_path = os.path.join(output_path,os.path.join("registered",case_name+"_registered.ply"))
# Input path for reference osso
ref_path = os.path.join(output_path, os.path.join("tmp",case_base+"_skel_lying.ply"))
#print(ref_path)

# Registration function
def registration(points_A, points_B):
    # Centroids
    centroid_A = points_A.mean(axis=0)
    centroid_B = points_B.mean(axis=0)
    # Cross-covariance matrix
    centered_A = points_A - centroid_A
    centered_B = points_B - centroid_B
    H = np.dot(centered_A.T, centered_B)
    # Perform SVD to find rotation
    U, S, Vt = np.linalg.svd(H)
    # Rotation matrix
    rotation = np.dot(Vt.T, U.T)
    # Handle potential reflection
    if np.linalg.det(rotation) < 0:
        Vt[-1, :] *= -1
        rotation = np.dot(Vt.T, U.T)
    # Translation vector
    translation = centroid_B - np.dot(centroid_A, rotation)
    # Apply rotation and translation to points_A
    rotated_points_A = np.dot(points_A, rotation)
    aligned_points_A = rotated_points_A + translation
    # Distances to check if the registration worked
    #distances = np.linalg.norm(aligned_points_A - points_B, axis=1)
    '''
    print("Rotation Matrix:")
    print(rotation)
    print("Translation Vector:")
    print(translation)
    print("Aligned Points A:")
    print(aligned_points_A)
    print("Distances between aligned points_A and points_B:")
    print(distances)
    '''

    return(rotation, translation, aligned_points_A)

# Load the PLY file into a trimesh object
mesh_ref = trimesh.load(ref_path)
mesh_posed = trimesh.load(posed_path)

# Get the vertices (points) from the mesh
vertices_ref = mesh_ref.vertices
vertices_posed = mesh_posed.vertices

# Indexes of interest
index_pelvis = [2138, 1218, 1572]

# Retrieve the coordinates of the point at the given index
pelvis_ref = vertices_ref[index_pelvis]
pelvis_posed = vertices_posed[index_pelvis]

#print(pelvis_ref)
#print(pelvis_posed)

rotation, translation, pelvis_posed_registered = registration(pelvis_posed, pelvis_ref)

'''
# Visualisation of pelvis points for quick tests
selected_point_cloud = trimesh.points.PointCloud(pelvis_ref)
selected_point_cloud.export(registration_folder+'/pelvis-points/'+case_base+'_pelvis-ref.ply')
selected_point_cloud = trimesh.points.PointCloud(pelvis_posed)
selected_point_cloud.export(registration_folder+'/pelvis-points/'+case_base+'_pelvis-posed.ply')
'''

# Apply rotation
rotation_matrix = np.eye(4)
rotation_matrix[:3, :3] = rotation
mesh_posed.apply_transform(rotation_matrix)

# Find and apply remaining translation
vertices_posed_registered = mesh_posed.vertices
pelvis_posed_registered = vertices_posed_registered[index_pelvis]
pelvis_pr_centroid = pelvis_posed_registered.mean(axis=0)
pelvis_ref_centroid = pelvis_ref.mean(axis=0)
translation_matrix = np.eye(4)
translation_matrix[:3, 3] = pelvis_ref_centroid - pelvis_pr_centroid
mesh_posed.apply_transform(translation_matrix)

'''
# Visualisation of pelvis points for quick tests
selected_point_cloud = trimesh.points.PointCloud(pelvis_posed_registered)
selected_point_cloud.export(registration_folder+'/pelvis-points/'+case_base+'_pelvis-rotated.ply')
'''

# Save output
mesh_posed.export(case_path) 

# Save registration matrix to apply on the smplx mesh
registration_matrix = rotation_matrix + translation_matrix
np.savetxt(registration_folder+'/'+case_base+'-registration-matrix.txt', registration_matrix, delimiter=',')

# Load test
#print(np.loadtxt(registration_folder+'/'+case_base+'-registration-matrix.txt', delimiter=','))