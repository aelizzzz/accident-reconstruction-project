import os
import bpy
import pickle

# SELECT THE MESH OBJECT BEFORE RUNNING THIS CODE
# This code assumes that a Meshcapade avatar of the right gender has been loaded.

# Path to the folder with the results and were the joints files will be saved
input_folder = "D:/Utilisateurs/Azilis/Documents/_Thesis/pose-estimation_unconstrained"
# Path to results folder
results_path = os.path.join(input_folder, "results")
# Path to the "joints-blender" folder where the results will be saved
output_path = os.path.join(input_folder, "joints-blender")
if not os.path.exists(output_path):
   os.makedirs(output_path)

# Iterate through the results folder
for root, dirs, files in os.walk(results_path):
    for case in dirs:
        # Load results file
        result_path = os.path.join(results_path, case, "000.pkl")
        
        # Load body shape
        with open(result_path, 'rb') as f:
            results_dict = pickle.load(f)
        betas = results_dict["betas"].flatten()
        print(betas)
        num_betas = betas.shape[0]
        obj = bpy.context.object
        bpy.ops.object.mode_set(mode='OBJECT')
        for i in range(num_betas):
            name = f"Shape{i:03d}"
            key_block = obj.data.shape_keys.key_blocks[name]
            value = betas[i]
            # Adjust key block min/max range to value
            if value < key_block.slider_min:
                key_block.slider_min = value
            elif value > key_block.slider_max:
                key_block.slider_max = value
            key_block.value = value
        bpy.ops.object.update_joint_locations()

        # Load pose    
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