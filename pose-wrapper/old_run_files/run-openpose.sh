#!/bin/env bash

cd /workspace/openpose/

./build/examples/openpose/openpose.bin --face --hand --image_dir IMAGES_PLACEHOLDER --write_json KEYPOINTS_PLACEHOLDER --write_images IMAGES_RENDERED_PLACEHOLDER --display 0

exit
