#!/bin/env bash

#SBATCH -A NAISS2023-22-708
#SBATCH -p alvis
#SBATCH -t 0-01:00:00
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

# Info on options
echo "Working folder path: $folder_path";
echo "Run OpenPose: $openpose";

# Test if there is a need to run OpenPose 
# (if not, then each image in the images folder has a corresponding keypoints,file)
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
    # Run OpenPose
    echo "Running OpenPose"
    apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/easymocap.img \
    bash -c '
    cd /workspace/openpose/
    ./build/examples/openpose/openpose.bin --face --hand --image_dir '$images' --write_json '$keypoints' --write_images '$images_rendered' --display 0
    exit 
    '

else    
    echo "Error: choose true or false for -o argument"
fi

# Run SMPLX (no visualisation, no screen when rnning via a jobscript)
echo "Running SMPLifyX with no visualisation and fitting smplx with "$bmi_option" height and weight"
apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/smplify_joints_not-constrained.sif \
bash -c '
cd /workspace/smplify-x/
python3.8 smplifyx/main.py --config cfg_files/fit_smplx.yaml --data_folder '$folder_path' --output_folder '$folder_path' --visualize="False" --model_folder models/ --vposer_ckpt ../vposer_v1_0/ --part_segm_fn smplx_parts_segm.pkl --use_vposer True --gender male
'

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
apptainer exec --fakeroot --writable-tmpfs /mimer/NOBACKUP/groups/snic2022-22-770/Azilis_workspace/singularity_image/smplx_new.sif \
bash -c 'pip install --force-reinstall pip==19
pip install chumpy
cd /workspace/smplx/
sed -i '5d' config_files/smplx2smpl.yaml
echo "Conversion SMPX to SMPL"
rm meshes/smplx/*.ply
for file in '$smplx'/*
do
    echo $file
    cp $file meshes/smplx
    python3 -m transfer_model --exp-cfg config_files/smplx2smpl.yaml
    mv -v output/* '$smpl'
done
'


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