#### World Space Position

```python
armature = bpy.data.objects['SMPLX-male']
for bone in armature.pose.bones:
    head_world_position = armature.matrix_world @ bone.head
    print(f"Bone: {bone.name}, Head Position in World Space: {head_world_position*1000}")
```
## To plot bone as sphere in Blender
```
import bpy

armature = bpy.data.objects['SMPLX-male']  # Replace with your armature's name
bpy.ops.object.select_all(action='DESELECT')  # Deselect all objects

for bone in armature.pose.bones:
    # Create a mesh sphere at the bone's head position
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.02, location=armature.matrix_world @ bone.head)
    sphere = bpy.context.object  # Get the newly created sphere
    sphere.name = f"Joint_{bone.name}"  # Rename the sphere to match the bone name
    sphere.show_in_front = True  # Make the sphere draw in front of other objects