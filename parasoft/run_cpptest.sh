#!/bin/bash -x

# needs to be exported - CMake extension uses this variable
export CPPTEST_HOME=$HOME/parasoft/cpptest-std-2022.2.0

# cleanup
# rm -rf build_cpputest *.clog *.utlog
rm -rf ./sandbox
mkdir ./sandbox
pushd ./sandbox

# clone my fork of the original CppUTest repo
# checkout my branch for experiments
git clone https://github.com/bczwartk/cpputest.git -b cpptest_cpputest

# build CppUTest and examples
mkdir ./build_cpputest
cmake -S cpputest -B ./build_cpputest -DCPPTEST_COVERAGE=ON
make -C ./build_cpputest -j4 clean all

# run examples
./build_cpputest/examples/AllTests/ExampleTests -v
./build_cpputest/tests/CppUTest/CppUTestTests -v
./build_cpputest/tests/CppUTestExt/CppUTestExtTests -v

# C/C++test data check
ls -l ./cpptest_results.utlog
ls -l ./build_cpputest/examples/AllTests/cpptest_results.utlog
ls -l ./build_cpputest/cpptest-coverage/CppUTest/CppUTest.clog 
ls -alrt ./build_cpputest/cpptest-coverage/CppUTest/.cpptest/

# generate reports
# rm -rf ./reports
$CPPTEST_HOME/cpptestcli \
    -showdetails \
    -workspace ./build_cpputest/cpptest-coverage/CppUTest \
    -input ./build_cpputest/cpptest-coverage/CppUTest/CppUTest.clog \
    -input ./cpptest_results.utlog \
    -input ./build_cpputest/examples/AllTests/cpptest_results.utlog \
    -module ./cpputest \
    -config "builtin://Unit Testing" \
    -report ./reports
ls -lart ./reports

popd


