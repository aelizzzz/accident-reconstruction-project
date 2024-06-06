# Wrapper for the pose estimation pipeline

Pipeline to perform pose estimation from single images. 

This provides Openpose 2D joints estimation, SMPLX and SMPL 3D pose estimation, OSSO skeleton  estimation, performs rigid registration of the pelvic bone to get an appropriate position of the regressed 3D joints, and finally outputs a LS-Dyna keyfile to position the THUMS body model.

## Run on Alvis

Ensure that you have access to the files in the following folder since this is where the containers used in this pipeline are stored:
`/mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image`.

### First part of the pipeline

Inputs:
```
└── 📁workingFolder
    └── 📁images
        └── example.jpg
    └── 📁keypoints (optional)
        └── example_keypoints.json
    └── 📁bmi (optionnal)
        └── example_bmi.json
```

- Format of the keypoints files: OpenPose keypoints output file
- Format of the bmi file (example)
```json
{
    "height": 183.0,
    "weight": 130.0
}
```

On Alvis, cd to the `wrapper` directory then run:

```Shell
sbatch main-part1.sh -f FOLDER_PATH -o true -b free
```

FOLDER_PATH should be the path to the working folder.

The following options available:
1. `-o` (required): `false` if OpenPose keypoints are already available (in this case the `openpose` folder needs to be defined, only one person per image/keypoints case) or `true` if OpenPose keypoints are not available and thus running OpenPose is required.
2. `-b` (required): `free` if there are no constraints to be applied on the height and weight of the people of interest, `fixed` if the height and weight should be the same for all cases and `personalized` if there is height and weight information available for each single person. In this case, there should be only one person per image, and the `bmi` folder needs to be defined. 
3. `-h` and `-w` (optional): if the option `-b fixed` is used, then these options should be defined as the fixed height (cm, float) and weight (kg, float)

### Second part of the pipeline

Inputs:
```
└── 📁workingFolder
    └── Outputs of the first part
        ... 
    └── 📁joints-blender
        └── example_joints-blender.txt
```

Currently, the new joints have to be manually generated using Blender and the Meshcapade SMPL Add-on:
- In the Layout window, go to the Meshcapade add-on
- Generate an SMPLX avatar of the required gender (male, female, neutral)
- If needed, change the height and weight or directly the beta shape parameters (Editor > Data > Shape parameters from 00 to 09)
- For only one pose: Load the pose from the .pkl file saved in the results folder in part 1 of the pipeline, then from the Scripting window, run the `smplx_blender_single_file.py` script (don't forget to update the path to save the file)
- To iterate on the entire results folder: from the Scripting window, run the `smplx_blender_loop.py` script (don't forget to update the input folder path and the output folder path)
- Afterwards, all the joints files should be saved in or moved to the joints-blender folder in order to be able to run part 2

Then, run
```Shell
sbatch main-part2.sh -f FOLDER_PATH
```

## Output file structure

Example of the output structure for one input image with one person in it:
```
└── 📁workingFolder
    └── conf.yaml
    └── 📁images
        └── 📁example
            ├── 000
        └── example.jpg
    └── 📁images-rendered
        └── example_rendered.png
    └── 📁joints
        └── example_joints.json
        └── 📁joints-registered
            └── example_joints-registered.json
            └── example_joints-registered.ply
            └── example_joints.ply
    └── 📁joints-blender
        └── test_joints-blender.txt
    └── 📁joints-matlab
        └── test_joints-registered.txt
    └── 📁keyfiles-ls-dyna
        └── test_Positioning_cables.k
    └── 📁keypoints
        └── example_keypoints.json
    └── 📁meshes
        └── 📁example
            └── 000.obj
    └── 📁meshes-smpl
        └── example.obj
        └── example.pkl
    └── 📁meshes-smplx
        └── example.obj
    └── 📁osso
        └── example_skel_posed.ply
        └── 📁registered
            └── example_skel_posed_registered.ply
            └── example_skel_posed_rotated.ply
        └── 📁tmp
            └── example_skel_lying.pkl
            └── example_skel_lying.ply
            └── example_star_lying.ply
            └── example_star_posed.pkl
            └── example_star_posed.ply
    └── 📁registration
        └── example-registration-matrix.txt
        └── 📁pelvis-points
            └── example_joints.ply
    └── 📁results
        └── 📁example
            └── 000.pkl
```

## Improvement suggestions

- Incorporate the Blender Add-on step in the pipeline