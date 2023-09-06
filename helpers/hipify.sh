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

# now to hipify all other source files that weren't under "cuda" directories
# hipify in-place for these files

OTHER_DIRS="
./src
./src/application
./src/boosting
./src/c_api.cpp
./src/cuda
./src/hip
./src/io
./src/main.cpp
./src/metric
./src/network
./src/objective
./src/treelearner
"

for DIR in $OTHER_DIRS
do
    for EXT in cpp h hpp hip
    do
        for FILE in $(find ${DIR} -name *.${EXT})
        do
            if [[ $FILE == */cuda/* ]] || [[ $FILE == */hip/* ]]
            then
                echo "skipping  $FILE"
            else
                echo "hipifying $FILE in-place"
                hipify-perl $FILE -inplace &
            fi
        done
    done
done

echo "waiting for all hipify-perl invocations to finish"
wait

echo "rewriting cuda to hip headers"
for DIR in ./src ./include
do
    for EXT in cpp h hpp hip
    do
        for FILE in $(find ${DIR} -name *.${EXT})
        do
            sed -i s@LightGBM/cuda@LightGBM/hip@g $FILE
            echo $FILE
        done
    done
done
