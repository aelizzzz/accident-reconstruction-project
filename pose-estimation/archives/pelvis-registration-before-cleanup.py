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
joints_folder = sys.argv[4]
joints_registered_folder = sys.argv[5]

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


###########################################
############ JOINTS PART ##################


# Load the regressed joints
joints_path = os.path.join(joints_folder, case_base+"_joints-blender.txt")
with open(joints_path, "r") as file:
    data = file.read()
pattern = r"\((.*?)\)"
matches = re.findall(pattern, data)
joints=np.zeros((len(matches), 3))
for i in range(len(matches)):
    temp = matches[i].split(", ")
    temp = [float(x) for x in temp]
    joints[i] = temp

# Visualisation of joints for quick tests
selected_point_cloud = trimesh.points.PointCloud(joints)
selected_point_cloud.export(os.path.join(joints_folder,case_base+'_joints.ply'))

# Joints were rotated 90 degrees around x compared to smplx and thus osso
# So invert that before applying the transformation
rotation_x = np.array([
    [1, 0, 0],  # No change in the X-axis
    [0, 0, -1],  # Z-axis becomes Y-axis
    [0, 1, 0]  # Y-axis becomes -Z-axis
])
joints = np.dot(joints, rotation_x)
# Apply rotation to regressed joints
rotated_joints = np.dot(joints, rotation)
# And back to the original orientation 
rotated_joints = np.dot(rotated_joints, np.transpose(rotation_x))
# The range of values between the joints and the vertices for osso 
# are completely different so the translation cannot be applied this way.


#Version 0
'''
# Find translation using reference pelvis centroid in Tailang's example used by Natalia
pelvis = np.array([[1.1677, -12.6690, 898.5430], [57.3114, 10.8055, 804.0013], [-56.7019, 3.8898, 793.3762]])
centroid = pelvis.mean(axis=0)
pelvis_regressed = np.array([rotated_joints[8], rotated_joints[9], rotated_joints[12]])
centroid_regressed = pelvis_regressed.mean(axis=0)
translation = centroid - centroid_regressed
aligned_joints = rotated_joints + translation
'''

#Version 1
# Find and apply remaining translation using position of the pelvis node in THUMS
pelvis_node_ref = np.array([-5.68007, -1.40311, 9.74604])
pelvis_node_rotated = rotated_joints[1]
translation = pelvis_node_ref - pelvis_node_rotated
aligned_joints = rotated_joints + translation

'''
#Version 2 BROKEN, TO FIX
# Joints were saved in mm, and osso is in meters
# Conversion to use the same translation as for OSSO
rotated_joints = rotated_joints / 1000 # in meters
aligned_joints = rotated_joints + translation_matrix[:3, 3]
# Then back in mm to match the next step of the pipeline
aligned_joints *= 1000 # in millimeters
'''

# Save the transformed joints back in the format for Natalia's Matlab code
joints_registered_path = os.path.join(joints_registered_folder, case_base+"_joints-registered.txt")
jointsNames = ['root', 'pelvis', 'left_hip', 'left_knee', 'left_ankle', 'left_foot', 'right_hip', 'right_knee', 'right_ankle', 'right_foot', 'spine1', 'spine2', 'spine3', 'neck', 'head', 'jaw', 'left_eye', 'right_eye', 'left_collar', 'left_shoulder', 'left_elbow', 'left_wrist', 'left_index1', 'left_index2', 'left_index3', 'left_middle1', 'left_middle2', 'left_middle3', 'left_pinky1', 'left_pinky2', 'left_pinky3', 'left_ring1', 'left_ring2', 'left_ring3', 'left_thumb1', 'left_thumb2', 'left_thumb3', 'right_collar', 'right_shoulder', 'right_elbow', 'right_wrist', 'right_index1', 'right_index2', 'right_index3', 'right_middle1', 'right_middle2', 'right_middle3', 'right_pinky1', 'right_pinky2', 'right_pinky3', 'right_ring1', 'right_ring2', 'right_ring3', 'right_thumb1', 'right_thumb2', 'right_thumb3']
with open(joints_registered_path, "w") as file:
    for i in range(len(jointsNames)):
        formatted_string = '<Vector (%.4f, %.4f, %.4f)>' % (aligned_joints[i][0], aligned_joints[i][1], aligned_joints[i][2])
        line = "Bone: "+jointsNames[i]+", Head Position in World Space: "+formatted_string
        file.write(line + "\n")

# Visualisation of registered joints for quick tests
selected_point_cloud = trimesh.points.PointCloud(aligned_joints)
selected_point_cloud.export(os.path.join(joints_registered_folder, case_base+'_joints-registered.ply'))
