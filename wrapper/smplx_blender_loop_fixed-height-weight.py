import os
import bpy

# This script assumes that an avatar of the correct gender 
# and shape parameters has already been loaded using the 
# Meshcapade Add-on

# Path to the folder with the results and were the joints files will be saved
input_folder = "D:/Utilisateurs/Azilis/Documents/_Thesis/pose-estimation_constrained-average-height-weight"
# Path to results folder
results_path = os.path.join(input_folder, "results")
# Path to the "joints-blender" folder where the results will be saved
output_path = os.path.join(input_folder, "joints-blender")
if not os.path.exists(output_path):
   os.makedirs(output_path)

# Iterate through the results folder
for root, dirs, files in os.walk(results_path):
    for case in dirs:
        # Load pose
        result_path = os.path.join(results_path, case, "000.pkl")    
        bpy.ops.object.set_pose_correctives()
        bpy.ops.object.snap_to_ground_plane()
        bpy.ops.object.load_pose(filepath=result_path, anim_format='blender')
        # Save joints
        joints_path = os.path.join(output_path, case+"_joints-blender.txt")
        armature = bpy.data.objects['SMPLX-male']
        with open(joints_path, "w") as file:
            for bone in armature.pose.bones:
                head_world_position = armature.matrix_world @ bone.head
                line=f"Bone: {bone.name}, Head Position in World Space: {head_world_position*1000}"
                print(line)
                file.write(line+'\n')
