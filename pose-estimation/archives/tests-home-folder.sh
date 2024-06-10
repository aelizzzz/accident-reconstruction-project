#!/bin/env bash

#SBATCH -A NAISS2023-22-708
#SBATCH -p alvis
#SBATCH -t 0-00:01:00
#SBATCH --gpus-per-node=A40:1
#SBATCH -J test

#Get the original path of the jobscript
if [ -n $SLURM_JOB_ID ];  then
    # if started with slurm, check the original location through scontrol and $SLURM_JOB_ID
    SCRIPT_PATH=$(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
else
    # otherwise: started with bash. Get the real location.
    SCRIPT_PATH=$(realpath $0)
fi

# Get path of the folder that contains the wrapper and singularity image directory
HOME_FOLDER=$(dirname $(dirname $SCRIPT_PATH))
echo "Home folder: " $HOME_FOLDER
