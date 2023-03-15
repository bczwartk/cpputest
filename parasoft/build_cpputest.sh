#!/bin/bash -x

# build CppUTest libraries
# should be run in the root of cpputest project

CPPUTEST_LIB_DIR=`pwd`/lib
BUILD_DIR=`pwd`/cpputest_build

rm -rf ${BUILD_DIR} ${CPPUTEST_LIB_DIR}
mkdir -p ${BUILD_DIR}
pushd ${BUILD_DIR}

autoreconf .. -i
../configure
make SILENCE=
cp -r ./lib ../

popd

ls -l ./lib

