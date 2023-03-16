#!/bin/bash -x

# assumes that CppUTest library was already built and is available in ../lib
# see ../parasoft/build_cpputest.sh


# common variables
# - C/C++test installation locations
CPPTEST_PRO_HOME=${HOME}/parasoft/cpptest-pro-2022.2.0
CPPTEST_STD_HOME=${HOME}/parasoft/cpptest-std-2022.2.0

# cpptestcc coverage engine
CPPTESTCC=${CPPTEST_STD_HOME}/bin/cpptestcc
# CPPTESTCC=${CPPTEST_PRO_HOME}/bin/cpptestcc
CPPTESTCC_WORKSPACE=`pwd`

# cpptestcc coverage engine settings (quiet by default, add -verbose for more output)
# CPPTESTCC_FLAGS="-compiler gcc_9-64 -line-coverage -mcdc-coverage -decision-coverage -workspace ${CPPTESTCC_WORKSPACE}"
CPPTESTCC_FLAGS="-psrc `pwd`/cpptestcc.psrc -workspace ${CPPTESTCC_WORKSPACE}"


# sanity check - this just builds and runs tests in verbose mode, no C/C++test
# make clean all SILENCE= CPPUTEST_EXE_FLAGS=-v


# prepare C/C++test runtime library for coverage if not available yet
CPPTEST_RT_LIB=./cpptest-runtime/build/cpptest.o
if [ ! -d ./cpptest-runtime ] ; then
  cp -r ${CPPTEST_STD_HOME}/runtime ./cpptest-runtime
  # cp -r ${CPPTEST_PRO_HOME}/bin/engine/coverage/runtime ./cpptest-runtime
fi
if [ ! -f ${CPPTEST_RT_LIB} ] ; then
  pushd ./cpptest-runtime
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
#   for this project setting LDFLAGS or CPPUTEST_ADDITIONAL_LDFLAGS simply works
make clean all SILENCE= CPPUTEST_EXE_FLAGS=-v \
  CC="${CPPTESTCC} ${CPPTESTCC_FLAGS} -- gcc" \
  CXX="${CPPTESTCC} ${CPPTESTCC_FLAGS} -- g++" \
  CPPUTEST_ADDITIONAL_LDFLAGS=${CPPTEST_RT_LIB}


# the result will be a new coverage cache and runtime coverage data from the tests (.clog file)
ls -l ${CPPTESTCC_WORKSPACE}/.cpptest
ls -l ./cpptest_results.clog
ls -l ./cpptest_results.utlog


# generate report with coverage and CppUTest results
# note: this requires C/C++test Standard
# note: C/C++test Standard can only report line coverage
rm -rf ./reports
$CPPTEST_STD_HOME/cpptestcli \
    -showdetails \
    -workspace ${CPPTESTCC_WORKSPACE} \
    -input ./cpptest_results.clog \
    -module . \
    -config "builtin://Unit Testing" \
    -property dtp.project=CppUTestExamples \
    -report ./reports
ls -lart ./reports


# generate advanced coverage reports
# note: this requires C/C++test Professional and Eclipse project
# note: this will *not* generate CppUTest test reports (see Standard above)


# TODO:
# + setup example project and automate running CppUTests
# + create C/C++test runtime library if needed
# + instrument builds with cpptestcc
# + generate coverage reports with C/C++test Standard
# - generate unit test reports with C/C++test Standard
# - collect coverage from application code (exclusions)
# - generate reports for advanced coverage metrics with C/C++test Professional
# - send results to DTP
# - add another folder with more CppUTests build as a separate executable
# - collect coverage from the new folder
# - merge coverage from both tests


