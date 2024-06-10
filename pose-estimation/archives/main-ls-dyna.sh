#!/bin/env bash

#SBATCH -A NAISS2023-22-708
#SBATCH -p alvis
#SBATCH -t 0-00:40:00
#SBATCH --gpus-per-node=A40:1
#SBATCH -J tests

while getopts f:o: flag
do
    case "${flag}" in
        f) folder_path=${OPTARG};;
    esac
done

cd /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/wrapper

echo "Test alignement joints blender"
jointsBlender=$folder_path"/joints-blender"
jointsMatlab=$folder_path"/joints-registered"
mkdir -p $jointsMatlab
module load TensorFlow-Graphics/2021.12.3-foss-2021b-CUDA-11.4.1
find $jointsBlender -maxdepth 1 -type f -name "*.txt" -print0 | while IFS= read -r -d '' file
do 
    python pelvis-registration-blender.py $file $jointsBlender $jointsMatlab
done
module purge

# Create keyfile for positioning from the joints
#echo:
echo "Creating positioning keyfiles"
keyfiles=$folder_path"/keyfiles-ls-dyna"
mkdir -p $keyfiles
module load MATLAB
for file in "$jointsMatlab"/*.txt
do 
    echo "Preparing k-file for: " $file
    matlab -nodesktop -singleCompThread -batch "generateKeyfile('$file','$keyfiles'); exit"
done
module purge

echo "Done"