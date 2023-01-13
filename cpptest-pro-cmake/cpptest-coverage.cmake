#
# CMake extension for integrating C/C++test Professional code coverage.
#

# Enable C/C++test code coverage integration:
#   cmake -DCPPTEST_COVERAGE=ON ...
option(CPPTEST_COVERAGE "Enable C/C++test code coverage integration")

set(_THIS_MODULE_BASE_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(_THIS_MODULE_TEMPLATES_DIR "${_THIS_MODULE_BASE_DIR}/cpptest.templates")

function (cpptest_enable_coverage)
  if(CYGWIN OR MSYS)
    execute_process(COMMAND cygpath
                            -m
                            ${CMAKE_SOURCE_DIR}
                    OUTPUT_VARIABLE CPPTEST_SOURCE_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND cygpath
                            -m
                            ${CMAKE_BINARY_DIR}
                    OUTPUT_VARIABLE CPPTEST_BINARY_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  else()
    set(CPPTEST_BINARY_DIR "${CMAKE_BINARY_DIR}")
    set(CPPTEST_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
  endif()

  # Configure C/C++test compiler identifier
  set(CPPTEST_COMPILER_ID "gcc_9-64")
  # Configure coverage type(s) - see 'cpptestcc -help' for details
  set(CPPTEST_COVERAGE_TYPE_FLAGS -optimized-line-coverage)
  # Configure C/C++test project name
  set(CPPTEST_PROJECT_NAME ${CMAKE_PROJECT_NAME})
  # Configure coverage workspace folder
  set(CPPTEST_COVERAGE_WORKSPACE ${CPPTEST_SOURCE_DIR}/../cpptest-coverage/${CPPTEST_PROJECT_NAME})
  # set(CPPTEST_COVERAGE_WORKSPACE ${CPPTEST_SOURCE_DIR})
  # Configure coverage log file
  set(CPPTEST_COVERAGE_LOG_FILE ${CPPTEST_COVERAGE_WORKSPACE}/${CPPTEST_PROJECT_NAME}.clog)
  # Configure C/C++test installation directory
  set(CPPTEST_HOME "" CACHE STRING "C/C++test installation directory")
  if(CPPTEST_HOME)
    set(CPPTEST_HOME_DIR ${CPPTEST_HOME})
  else()
    set(CPPTEST_HOME_DIR $ENV{CPPTEST_HOME})
  endif()

  # Build C/C++test coverage runtime library
  set(CPPTEST_RUNTIME_BUILD_DIR ${CMAKE_BINARY_DIR}/cpptest-runtime)

  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
                          ${CPPTEST_RUNTIME_BUILD_DIR})
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${CPPTEST_HOME_DIR}/bin/engine/coverage/runtime
                          "-G${CMAKE_GENERATOR}"
                          "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
                          "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
                          "-DCPPTEST_LOG_FILE_NAME=${CPPTEST_COVERAGE_LOG_FILE}"
                  WORKING_DIRECTORY
                          ${CPPTEST_RUNTIME_BUILD_DIR})
  execute_process(COMMAND ${CMAKE_COMMAND}
                          --build . --verbose
                  WORKING_DIRECTORY
                          ${CPPTEST_RUNTIME_BUILD_DIR})

  if(MSVC)
    set(CPPTEST_LINKER_FLAGS
        "\"${CPPTEST_RUNTIME_BUILD_DIR}/cpptest_shared.lib\"")

    # Add C/C++test coverage runtime library to shared library linker flags
    set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} ${CPPTEST_LINKER_FLAGS}"
        PARENT_SCOPE)
  else()
    set(CPPTEST_LINKER_FLAGS
        "-Wl,--whole-archive \"${CPPTEST_RUNTIME_BUILD_DIR}/libcpptest_static.a\" -Wl,--no-whole-archive")
  endif()

  # Add C/C++test coverage runtime library to executable linker flags
  set(CMAKE_EXE_LINKER_FLAGS
      "${CMAKE_EXE_LINKER_FLAGS} ${CPPTEST_LINKER_FLAGS}"
      PARENT_SCOPE)

  # Configure cpptestcc command line
  set(CPPTEST_CPPTESTCC ${CPPTEST_HOME_DIR}/bin/cpptestcc)
  set(CPPTEST_CPPTESTCC_OPTS
      -workspace "${CPPTEST_COVERAGE_WORKSPACE}"
      -compiler ${CPPTEST_COMPILER_ID}
      ${CPPTEST_COVERAGE_TYPE_FLAGS}
      -exclude "regex:*"
      -include "regex:${CPPTEST_SOURCE_DIR}/*"
      -exclude "regex:${CPPTEST_BINARY_DIR}/*"
      -ignore "regex:${CPPTEST_BINARY_DIR}/*")

  # Use advanced settings file for cpptestcc, if exists
  if(EXISTS "${CMAKE_SOURCE_DIR}/.cpptestcc")
    set(CPPTEST_CPPTESTCC_OPTS
        ${CPPTEST_CPPTESTCC_OPTS}
        -psrc "${CPPTEST_SOURCE_DIR}/.cpptestcc")
  endif()

  # Prefix C++ compiler with cpptestcc
  set(CMAKE_CXX_COMPILER_LAUNCHER
      ${CMAKE_CXX_COMPILER_LAUNCHER} ${CPPTEST_CPPTESTCC} ${CPPTEST_CPPTESTCC_OPTS} -- PARENT_SCOPE)

  # Prefix C compiler with cpptestcc
  set(CMAKE_C_COMPILER_LAUNCHER
      ${CMAKE_C_COMPILER_LAUNCHER} ${CPPTEST_CPPTESTCC} ${CPPTEST_CPPTESTCC_OPTS} -- PARENT_SCOPE)

  # For compatibility with older CMake versions:  
  # set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE
  #    "${CPPTEST_CPPTESTCC} ${CPPTEST_CPPTESTCC_OPTS} -- ")

  # Pre-configure C/C++test workspace and project
  set(CPPTEST_LINK_NAME ${CPPTEST_PROJECT_NAME})
  set(CPPTEST_LINK_TARGET ${CPPTEST_SOURCE_DIR})
  set(CPPTEST_BDF ${CPPTEST_BINARY_DIR}/compile_commands.json)

  configure_file(
    ${_THIS_MODULE_TEMPLATES_DIR}/parasoft.in
    ${CPPTEST_COVERAGE_WORKSPACE}/.parasoft @ONLY
    NEWLINE_STYLE UNIX)

  configure_file(
    ${_THIS_MODULE_TEMPLATES_DIR}/linked_folder.in
    ${CPPTEST_COVERAGE_WORKSPACE}/.linked_folder @ONLY
    NEWLINE_STYLE UNIX)
    file(STRINGS ${CPPTEST_COVERAGE_WORKSPACE}/.linked_folder fLinked)
    string(APPEND CPPTEST_LINKED_FOLDERS "\n" ${fLinked})

  configure_file(
    ${_THIS_MODULE_TEMPLATES_DIR}/project.in
    ${CPPTEST_COVERAGE_WORKSPACE}/.project @ONLY
    NEWLINE_STYLE UNIX)

  # Add helper target for generating coverage report with cpptestcli
  add_custom_target(cpptest_coverage_report
    COMMAND
    ${CPPTEST_HOME_DIR}/cpptestcli
        -data "${CPPTEST_COVERAGE_WORKSPACE}/.."
        -import "${CPPTEST_COVERAGE_WORKSPACE}"
        -report "${CPPTEST_COVERAGE_WORKSPACE}/reports"
        -config "builtin://Load Application Coverage"
	    -localsettings ${_THIS_MODULE_BASE_DIR}/local.settings
        -showdetails -appconsole stdout
        -resource ATM_Cpp14_lib
        )

endfunction()

if(CPPTEST_COVERAGE)
  cpptest_enable_coverage()
endif()
