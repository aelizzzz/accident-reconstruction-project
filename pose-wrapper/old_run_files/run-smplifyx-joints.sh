#!/bin/env bash

cd /workspace/smplify-x/

python3.8 smplifyx/main_joints.py --config cfg_files/fit_smplx.yaml --data_folder FOLDER_PLACEHOLDER --output_folder FOLDER_PLACEHOLDER --save_meshes="True" --visualize="False" --model_folder models/ --vposer_ckpt ../vposer_v1_0/ --part_segm_fn smplx_parts_segm.pkl --use_vposer True --gender male

exit