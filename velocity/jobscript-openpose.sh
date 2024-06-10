#!/bin/env bash

#SBATCH -A NAISS2023-22-708
#SBATCH -p alvis
#SBATCH -t 0-00:20:00
#SBATCH --gpus-per-node=A40:1
#SBATCH -J openpose

while getopts f: flag
do
    case "${flag}" in
        f) folder_path=${OPTARG};;
    esac
done

apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/easymocap.img \
bash -c '
# Choose directory to run
dir='$folder_path'
cd /workspace/openpose/
# Loop on different cases (subdirectories)
for subdir in "$dir"/*; do
    if [ -d "$subdir" ]; then
        echo "$subdir"
        ./build/examples/openpose/openpose.bin --image_dir "$subdir/images" --write_json "$subdir/keypoints-openpose" --write_images "$subdir/images-rendered" --display 0
    fi
done

exit
'