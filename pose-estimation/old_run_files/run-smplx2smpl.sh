#!/bin/env bash

cd /workspace/smplx/
sed -i '5d' config_files/smplx2smpl.yaml

# Copy them for smplx2smpl
echo "Conversion SMPX to SMPL"
cp SMPLX_PLACEHOLDER/* meshes/smplx
rm meshes/smplx/*.ply

python3 -m transfer_model --exp-cfg config_files/smplx2smpl.yaml

cp -r output/. SMPL_PLACEHOLDER

exit
