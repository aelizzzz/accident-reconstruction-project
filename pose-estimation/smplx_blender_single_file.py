# This script assumes that an avatar of the correct gender 
# and shape parameters has already been loaded using the 
# Meshcapade Add-on, and that the pose has also been loaded

import bpy

# Update joint path
joints_path = "D:/Utilisateurs/Azilis/Documents/_Thesis/master-thesis-kth/blender-tests/test_joints-blender.txt"
armature = bpy.data.objects['SMPLX-male']
with open(joints_path, "w") as file:
    for bone in armature.pose.bones:
        head_world_position = armature.matrix_world @ bone.head
        line=f"Bone: {bone.name}, Head Position in World Space: {head_world_position*1000}"
        print(line)
        file.write(line+'\n')

