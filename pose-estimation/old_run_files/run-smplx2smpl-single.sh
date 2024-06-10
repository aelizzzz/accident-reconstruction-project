#!/bin/env bash

cd /workspace/smplx/
sed -i '5d' config_files/smplx2smpl.yaml

# Copy them for smplx2smpl
echo "Conversion SMPX to SMPL"
rm meshes/smplx/*.ply
for file in SMPLX_PLACEHOLDER/*
do
    echo $file
    cp $file meshes/smplx
    python3 -m transfer_model --exp-cfg config_files/smplx2smpl.yaml
    mv -v output/* SMPL_PLACEHOLDER
done

exit

