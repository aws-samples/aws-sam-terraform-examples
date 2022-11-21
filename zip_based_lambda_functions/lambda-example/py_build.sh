#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

src_code=$1
build_path=$2
output_name=$3
resource_type=$4

[[ -z "$src_code" ]]      && echo "ERROR: src_code is not defined"      && exit 1
[[ -z "$build_path" ]]    && echo "ERROR: build_path is not defined"    && exit 1
[[ -z "$output_name" ]]   && echo "ERROR: output_name is not defined"   && exit 1
[[ -z "$resource_type" ]] && echo "ERROR: resource_type is not defined" && exit 1

echo "building ${resource_type} ${src_code} into ${build_path}"

temp_path=${build_path}/tmp_building
if [[ "${resource_type}" == "Layer" ]]; then
  temp_path=${build_path}/tmp_building/python
  echo "new path ${temp_path}"
fi

pwd
mkdir -p ${build_path}
rm -rf ${build_path}/*
mkdir -p ${build_path}/tmp_building
mkdir -p ${temp_path}
cp -r $src_code/* ${temp_path}
pip install -r ${temp_path}/requirements.txt -t ${temp_path}/.
pushd ${build_path}/tmp_building/ && zip -r $output_name . && popd
mv "${build_path}/tmp_building/${output_name}" "${build_path}/$output_name"
rm -rf ${build_path}/tmp_building