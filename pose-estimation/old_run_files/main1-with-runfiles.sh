#!/bin/env bash

#SBATCH -A NAISS2023-22-708
#SBATCH -p alvis
#SBATCH -t 0-10:00:00
#SBATCH --gpus-per-node=A40:1
#SBATCH -J pose-estimation-part1

while getopts f:o: flag
do
    case "${flag}" in
        f) folder_path=${OPTARG};;
        o) openpose=${OPTARG};;
    esac
done
echo "This is the first part of the pose estimation pipeline."
echo "Images path: $folder_path";
echo "Run OpenPose: $openpose";

cd /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/wrapper
#echo "$PWD"

# Test if there is a need to run OpenPose 
# (if not, then each image in the images folder has a corresponding keypoint)
if [ "$openpose" = false ]; then   
    echo "Using provided keypoints";
elif [ "$openpose" = true ]; then
    # Create results folders
    keypoints=$folder_path"/keypoints"
    images_rendered=$folder_path"/images-rendered"    
    echo "Creating $keypoints"
    mkdir -p $keypoints
    echo "Creating $images_rendered"
    mkdir -p $images_rendered

    # Edit run-openpose.sh to match the working folder (ugly, to fix?)
    images=$folder_path"/images"
    sed -i.bak 's@IMAGES_PLACEHOLDER@'$images'@g' run-openpose.sh
    sed -i 's@KEYPOINTS_PLACEHOLDER@'$keypoints'@g' run-openpose.sh
    sed -i 's@IMAGES_RENDERED_PLACEHOLDER@'$images_rendered'@g' run-openpose.sh
    # Run OpenPose
    echo "Running OpenPose"
    apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/easymocap.img /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/wrapper/run-openpose.sh
    # Once done, return to placeholders for next time (ugly, to fix?)
    cp run-openpose.sh.bak run-openpose.sh
    rm run-openpose.sh.bak
else    
    echo "Error: choose true or false for -o argument"
fi

# Run SMPLX (no visualisation)

echo "Running SMPLifyX with no visualisation"
# Version with no constraints on height and weight
sed -i.bak 's@FOLDER_PLACEHOLDER@'$folder_path'@g' run-smplifyx-joints-blender.sh
apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/smplify_joints_not-constrained.sif /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/wrapper/run-smplifyx-joints-blender.sh
cp run-smplifyx-joints-blender.sh.bak run-smplifyx-joints-blender.sh
rm run-smplifyx-joints-blender.sh.bak


# Version with constraints on height and weight
#sed -i.bak 's@FOLDER_PLACEHOLDER@'$folder_path'@g' run-smplifyx-joints-constrained.sh
#apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/smplify_joints_constrained.sif /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/wrapper/run-smplifyx-joints-constrained.sh
#cp run-smplifyx-joints-tailang.sh.bak run-smplifyx-joints-tailang.sh
#rm run-smplifyx-joints-tailang.sh.bak

# Get the SMPLX files and rename them for clarity

echo "Getting SMPLX files and renaming them for clarity"
meshes=$folder_path"/meshes"
smplx=$folder_path"/meshes-smplx"
smpl=$folder_path"/meshes-smpl"
cp -a $meshes $smplx
chmod -R 750 $smplx
module load Anaconda3/2022.05
python move_rename.py $smplx
module purge

# Run SMPLX to SMPL

echo "Running SMPLX to SMPL conversion"
mkdir -p $smpl
sed -i.bak 's@SMPLX_PLACEHOLDER@'$smplx'@g' run-smplx2smpl-single.sh
sed -i 's@SMPL_PLACEHOLDER@'$smpl'@g' run-smplx2smpl-single.sh
apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/smplx_with_chumpy.sif /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/wrapper/run-smplx2smpl-single.sh
cp run-smplx2smpl-single.sh.bak run-smplx2smpl-single.sh
rm run-smplx2smpl-single.sh.bak

# Run OSSO
osso=$folder_path"/osso"
osso_tmp=$folder_path"/osso/tmp"
mkdir -p $osso
mkdir -p $osso_tmp

echo "Running OSSO"
apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/singularity_image/OSSO/OSSO_post.sif \
bash -c '
. /opt/conda/etc/profile.d/conda.sh
conda activate OSSO
cd /workspace/OSSO/
source osso_venv/bin/activate
for file in '$smpl'/*.obj
do 
    echo "Processing $file"
    python main.py --mesh_input "$file" --gender male -D -v
    mv out/*.ply '$osso'
    mv -v out/tmp/* '$osso_tmp'
    done
'

echo "Done running OSSO"

echo "Done running the first part of the pose estimation pipeline."