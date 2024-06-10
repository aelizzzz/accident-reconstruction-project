import trimesh
import os
import numpy as np
import sys
import ast
import json
import re

# Read arguments
posed_path = sys.argv[1]
joints_folder = sys.argv[2]
joints_registered_folder = sys.argv[3]

# Case name and path
case_name = posed_path.split("/")[-1]
case_name = case_name.split(".")[0]
case_base = case_name[0:len(case_name)-15]

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

# Retrieve the coordinates of the pelvis points
pelvis_posed = np.array([joints[1], joints[2], joints[6]])
# These are pelvis/left_hip/right_hip joints from Blender, with the same BETAS as in the constrained version of smplifyx
pelvis_ref = np.array([[1.2079, -13.5407, 1000.4656], [57.8379, 9.5709, 905.7139], [-57.1587, 2.5826, 895.0347]])

'''
# Visualisation of posed pelvis for quick tests
selected_point_cloud = trimesh.points.PointCloud(pelvis_posed)
selected_point_cloud.export(os.path.join(joints_registered_folder, case_base+'_pelvis-posed.ply'))
# Visualisation of ref pelvis for quick tests
selected_point_cloud = trimesh.points.PointCloud(pelvis_ref)
selected_point_cloud.export(os.path.join(joints_registered_folder, case_base+'_pelvis-ref.ply'))
'''

rotation, translation, pelvis_posed_registered = registration(pelvis_posed, pelvis_ref)

# Apply rotation
rotated_joints = np.dot(joints, rotation)
# Visualisation of rotated joints for quick tests
selected_point_cloud = trimesh.points.PointCloud(rotated_joints)
selected_point_cloud.export(os.path.join(joints_registered_folder, case_base+'_joints-rotated.ply'))

'''
# Find and apply remaining translation
centroid = pelvis_ref.mean(axis=0)
pelvis_rotated = np.array([rotated_joints[1], rotated_joints[2], rotated_joints[6]])
centroid_rotated = pelvis_rotated.mean(axis=0)
translation = centroid - centroid_rotated
pelvis_aligned = pelvis_rotated + translation
aligned_joints = rotated_joints + translation
'''

# Find and apply remaining translation using position of the pelvis node in THUMS
pelvis_node_ref = np.array([-5.68007, -1.40311, 9.74604])
pelvis_node_rotated = rotated_joints[1]
translation = pelvis_node_ref - pelvis_node_rotated
aligned_joints = rotated_joints + translation

'''
# Visualisation of rotated pelvis for quick tests
selected_point_cloud = trimesh.points.PointCloud(pelvis_rotated)
selected_point_cloud.export(os.path.join(joints_registered_folder, case_base+'_pelvis-rotated.ply'))
# Visualisation of registered pelvis for quick tests
selected_point_cloud = trimesh.points.PointCloud(pelvis_aligned)
selected_point_cloud.export(os.path.join(joints_registered_folder, case_base+'_pelvis-aligned.ply'))
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