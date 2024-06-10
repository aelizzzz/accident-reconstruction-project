#!/bin/env bash

#SBATCH -A NAISS2023-22-708
#SBATCH -p alvis
#SBATCH -t 0-00:40:00
#SBATCH --gpus-per-node=A40:1
#SBATCH -J pose-estimation-part2

while getopts f: flag
do
    case "${flag}" in
        f) folder_path=${OPTARG};;
    esac
done

echo "This is the second part of the pose estimation pipeline."

#Get the original path of the jobscript
if [ -n $SLURM_JOB_ID ];  then
    # if started with slurm, check the original location through scontrol and $SLURM_JOB_ID
    SCRIPT_PATH=$(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
else
    # otherwise: started with bash. Get the real location.
    SCRIPT_PATH=$(realpath $0)
fi

# Get path of the wrapper folder
WRAPPER_FOLDER=$(dirname $SCRIPT_PATH)
echo "Wrapper folder: " $WRAPPER_FOLDER
# cd there
cd $WRAPPER_FOLDER

# Use OSSO tmp and final results to perform a pelvis registration 
# and alignement of the body
# This step includes the transformation of the joints according to 
# the pelvis registration
echo "Registrating pelvis from OSSO"
osso=$folder_path"/osso"
osso_tmp=$folder_path"/osso/tmp"
registration=$folder_path"/registration-osso"
registration_pelvis=$folder_path"/registration-osso/pelvis-points"
osso_registered=$folder_path"/osso/registered"
mkdir -p $registration
mkdir -p $registration_pelvis
mkdir -p $osso_registered
mkdir -p $jointsMatlab
module load TensorFlow-Graphics/2021.12.3-foss-2021b-CUDA-11.4.1
find $osso -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file
do 
    python pelvis-registration-osso.py $osso $file $registration
done
module purge


echo "Registrating Blender joints for THUMS"
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

echo "Done with the second part of the pipeline"