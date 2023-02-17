#!/bin/bash -x

# needs to be exported - CMake extension uses this variable
export CPPTEST_HOME=$HOME/parasoft/cpptest-pro-2022.2.0

# cleanup
# rm -rf build_cpputest *.clog *.utlog
rm -rf ./sandbox
mkdir ./sandbox
pushd ./sandbox

# clone my fork of the original CppUTest repo
# checkout my branch for experiments
git clone https://github.com/bczwartk/cpputest.git -b cpptest_pro_cpputest

# build CppUTest and examples
mkdir ./build_cpputest
cmake -S cpputest -B ./build_cpputest -DCPPTEST_COVERAGE=ON -DCPPTEST_HOME=$CPPTEST_HOME
make -C ./build_cpputest -j4 clean all

# run examples
./build_cpputest/examples/AllTests/ExampleTests -v
./build_cpputest/tests/CppUTest/CppUTestTests -v
./build_cpputest/tests/CppUTestExt/CppUTestExtTests -v

# C/C++test data check
ls -l ./cpptest_results.utlog
ls -l ./build_cpputest/examples/AllTests/cpptest_results.utlog
ls -alrt ./cpptest-coverage/CppUTest/
ls -alrt ./cpptest-coverage/CppUTest/.cpptest/

# generate reports
rm -rf ./reports ./cpptest-coverage/workspace
$CPPTEST_HOME/cpptestcli \
    -showdetails -appconsole stdout -property console.verbosity=high \
    -data ./cpptest-coverage/workspace \
    -settings ./cpputest/parasoft/cpptest.properties \
    -import ./cpptest-coverage/CppUTest/ \
    -config 'builtin://Load Application Coverage' \
    -report ./reports
ls -lart ./reports

popd


