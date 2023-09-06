#!/bin/bash

CUDA_DIRS="
./src/boosting/cuda
./src/treelearner/cuda
./src/objective/cuda
./src/metric/cuda
./src/io/cuda
./src/cuda
./include/LightGBM/cuda
"

for CUDA_DIR in $CUDA_DIRS
do
    HIP_DIR=$(echo $CUDA_DIR | sed s/cuda/hip/)
    echo "mkdir -p $HIP_DIR"
    mkdir -p $HIP_DIR
    for CUDA_FILE in $CUDA_DIR/*
    do
        HIP_FILE=$(echo $CUDA_FILE | sed s/cuda/hip/)
        if [[ $HIP_FILE == *.cu ]]
        then
            HIP_FILE="${HIP_FILE%.cu}.hip"
        fi
        echo "hipifying $CUDA_FILE to $HIP_FILE"
        hipify-perl $CUDA_FILE -o=$HIP_FILE &
    done
done

echo "waiting for all hipify-perl invocations to finish"
wait

echo "rewriting cuda to hip headers"
for EXT in cpp h hpp hip
do
    for FILE in $(find ./src -name *.${EXT})
    do
        sed -i s@LightGBM/cuda@LightGBM/hip@g $FILE
    done
done
