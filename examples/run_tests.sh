#!/bin/bash -x

# Script to perform make-based build and run of CppUTest examples
# and to generate C/C++test coverage reports.
# It should be run in cpputest/examples folder.
# Assumes that CppUTest library was already built and is available in ../lib.
# See ../parasoft/build_cpputest.sh.


# common variables
# - C/C++test installation locations
CPPTEST_PRO_HOME=${HOME}/parasoft/cpptest-pro-2022.2.0
CPPTEST_STD_HOME=${HOME}/parasoft/cpptest-std-2022.2.0
DTP_PUBLISH=-publish

# cpptestcc coverage engine
CPPTESTCC=${CPPTEST_STD_HOME}/bin/cpptestcc
# CPPTESTCC=${CPPTEST_PRO_HOME}/bin/cpptestcc
CPPTESTCC_WORKSPACE=`pwd`

# cpptestcc coverage engine settings (quiet by default, add -verbose for more output)
# CPPTESTCC_FLAGS="-compiler gcc_9-64 -line-coverage -mcdc-coverage -decision-coverage -workspace ${CPPTESTCC_WORKSPACE}"
CPPTESTCC_FLAGS="-psrc `pwd`/cpptestcc.psrc -workspace ${CPPTESTCC_WORKSPACE}"

# build ID to tag results separately for each run
BUILD_ID="CppUTestExample_`date +%Y%m%d%H%M`"


# sanity check - this just builds and runs tests in verbose mode, no C/C++test
# make clean all SILENCE= CPPUTEST_EXE_FLAGS=-v


# prepare C/C++test runtime library for coverage if not available yet
CPPTEST_RT=`pwd`/cpptest-runtime
CPPTEST_RT_LIB=${CPPTEST_RT}/build/cpptest.o
if [ ! -d ${CPPTEST_RT} ] ; then
    cp -r ${CPPTEST_STD_HOME}/runtime ${CPPTEST_RT}
    # cp -r ${CPPTEST_PRO_HOME}/bin/engine/coverage/runtime ${CPPTEST_RT}
fi
if [ ! -f ${CPPTEST_RT_LIB} ] ; then
    pushd ${CPPTEST_RT}
    make
    popd
fi
ls -l ${CPPTEST_RT_LIB}


# cleanup old instrumentation cache if needed
rm -rf ${CPPTESTCC_WORKSPACE}/.cpptest
# cleanup old coverage data log if needed (it normally appends across runs)
rm -f ./cpptest_results.clog


# instrument for coverage and run tests 
# - prefix compiler with cpptestcc command line - this will instrument for coverage
# - add C/C++test runtime library to linker command line to add coverage API implementation;
#   try LDFLAGS or CPPUTEST_ADDITIONAL_LDFLAGS, or "+= ${CPPTEST_RT_LIB} in the makefile;
#   for this project setting LDFLAGS or CPPUTEST_ADDITIONAL_LDFLAGS simply works;
#   see also ../build/MakefileWorker.mk for non-intrusive ways to add extra options to the build
# - add flags to enable C/C++test Standard unit test listener;
#   note: do not touch CPPUTEST_CPPFLAGS, we cannot override it here as it has some CppUTest flags
make clean all \
    SILENCE= CPPUTEST_EXE_FLAGS=-v \
    CC="${CPPTESTCC} ${CPPTESTCC_FLAGS} -- gcc" \
    CXX="${CPPTESTCC} ${CPPTESTCC_FLAGS} -- g++" \
    CPPUTEST_ADDITIONAL_LDFLAGS=${CPPTEST_RT_LIB} \
    CPPUTEST_CFLAGS="-DPARASOFT_CPPTEST=1 -I${CPPTEST_RT}/include" \
    CPPUTEST_CXXFLAGS="-DPARASOFT_CPPTEST=1 -I${CPPTEST_RT}/include" \


# the result will be a new coverage cache and runtime coverage data from the tests (.clog file)
ls -l ${CPPTESTCC_WORKSPACE}/.cpptest
ls -l ./cpptest_results.clog
ls -l ./cpptest_results.utlog


# generate report with coverage and CppUTest results
# note: this requires C/C++test Standard
# note: C/C++test Standard can only report line coverage
if [ -f ./cpptest_results.clog ] ; then
    rm -rf ./reports_std
    ${CPPTEST_STD_HOME}/cpptestcli \
        -showdetails \
        -workspace ${CPPTESTCC_WORKSPACE} \
        -input ./cpptest_results.clog \
        -input ./cpptest_results.utlog \
        -module CppUTestExample=`pwd` \
        -config "builtin://Unit Testing" \
        -property dtp.project=CppUTest \
        -property build.id=${BUILD_ID} \
        -report ./reports_std \
        ${DTP_PUBLISH}
    ls -lart ./reports_std
fi


# generate advanced coverage reports
# note: this requires C/C++test Professional and Eclipse project
# note: this will *not* generate CppUTest test reports (see Standard above)
# note: instead of builtin test config to load coverage ('builtin://Load Application Coverage')
#       we use a custom one that only includes the selected coverage metrics
if [ -f ./cpptest_results.clog ] ; then
    # Eclipse workspace must be outside of the project folder (where .project is located)
    DATA_DIR=`pwd`/../cpptest_wksp
    rm -rf ${DATA_DIR}
    rm -rf ./reports_pro
    ${CPPTEST_PRO_HOME}/cpptestcli \
        -data ${DATA_DIR} \
        -import `pwd` \
        -config "`pwd`/../parasoft/Load Application Coverage CppUTest.properties" \
        -showdetails -appconsole stdout \
        -report reports_pro \
        -settings `pwd`/../parasoft/cpptest.properties \
        -property dtp.project=CppUTest \
        -property build.id=${BUILD_ID} \
        ${DTP_PUBLISH}
    ls -lart ./reports_pro
fi




# TODO:
# MVP:
# + setup example project and automate running CppUTests
# + create C/C++test runtime library if needed
# + instrument builds with cpptestcc
# + generate coverage reports with C/C++test Standard
# + generate unit test reports with C/C++test Standard
#   + add C/C++test test listener to the unit tests (enabled via #ifdef's)
#   + enable C/C++test test listener during the build
# + collect coverage from application code only (exclusions)
# + generate reports for advanced coverage metrics with C/C++test Professional
# + send results to DTP
# OPTIONAL:
# - add another folder with more CppUTests build as a separate executable
# - collect coverage from the new folder
# - merge coverage from both tests


