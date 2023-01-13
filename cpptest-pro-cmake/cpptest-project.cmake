#
# CMake extension for creating C/C++test Professional projects.
#

# Enable C/C++test project generator:
#   cmake -DCPPTEST_PROJECT=ON ...
option(CPPTEST_PROJECT "Enable C/C++test project generator")

set(_THIS_MODULE_BASE_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(_THIS_MODULE_TEMPLATES_DIR "${_THIS_MODULE_BASE_DIR}/cpptest.templates")

function(cpptest_add_executable TARGET)
  cmake_parse_arguments(
    ""
    "EXCLUDE_FROM_ALL"
    "CPPTEST_COMPILER_ID;CPPTEST_PROJECT_NAME;CPPTEST_PROJECT_LOC"
    "SOURCES;TARGETS;CPPTEST_PROJECT_FOLDERS"
    ${ARGN}
  )
  if(NOT _CPPTEST_COMPILER_ID)
      set(CPPTEST_COMPILER_ID gcc_9-64)
  else()
      set(CPPTEST_COMPILER_ID "${_CPPTEST_COMPILER_ID}")
  endif()

  if(NOT _CPPTEST_PROJECT_NAME)
      set(CPPTEST_PROJECT_NAME "${TARGET}")
  else()
      set(CPPTEST_PROJECT_NAME "${_CPPTEST_PROJECT_NAME}")
  endif()

  if(NOT _CPPTEST_PROJECT_LOC)
      set(CPPTEST_PROJECT_LOC "${CMAKE_CURRENT_SOURCE_DIR}")
  else()
      set(CPPTEST_PROJECT_LOC "${_CPPTEST_PROJECT_LOC}")
  endif()

  if(_EXCLUDE_FROM_ALL OR NOT CPPTEST_PROJECT)
      set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
  else()
      set(EXCLUDE_FROM_ALL)
  endif()

  # Compute extra sources from TARGETS
  foreach(t ${_TARGETS})
    get_target_property(t_source_dir ${t} SOURCE_DIR)
    get_target_property(t_sources ${t} SOURCES)
    foreach(t_source ${t_sources})
      get_filename_component(t_source_absolute ${t_source} ABSOLUTE BASE_DIR ${t_source_dir})
      list(APPEND _SOURCES "${t_source_absolute}")
    endforeach()
  endforeach(t)

  add_executable(${TARGET} ${EXCLUDE_FROM_ALL} ${_SOURCES})
  
  if(NOT CPPTEST_PROJECT)
    return()
  endif()
  
  set(CPPTEST_BDF ${CMAKE_CURRENT_BINARY_DIR}/${CPPTEST_PROJECT_NAME}.bdf)
  if (NOT RUN_ORIG_CMD)
    set(RUN_ORIG_CMD "no")
  endif()
  if(WIN32)
    set(OPTSCAN_NAME ${CPPTEST_PROJECT_NAME}_scan.bat)
    set(CPPTESTSCAN cpptestscan.bat.in)
    set(CPPTESTSCAN_EOL WIN32)
  else(WIN32)
    set(OPTSCAN_NAME ${CPPTEST_PROJECT_NAME}_scan.sh)
    set(CPPTESTSCAN cpptestscan.in)
    set(CPPTESTSCAN_EOL UNIX)
  endif(WIN32)

  configure_file(
    ${_THIS_MODULE_TEMPLATES_DIR}/${CPPTESTSCAN}
    ${CMAKE_CURRENT_BINARY_DIR}/${OPTSCAN_NAME} @ONLY
    NEWLINE_STYLE ${CPPTESTSCAN_EOL})

  configure_file(
    ${_THIS_MODULE_TEMPLATES_DIR}/parasoft.in
    ${CPPTEST_PROJECT_LOC}/.parasoft @ONLY
    NEWLINE_STYLE UNIX)

  # Generate linked folders configuration
  if(_CPPTEST_PROJECT_FOLDERS)
    foreach(f ${_CPPTEST_PROJECT_FOLDERS})
      string(REPLACE "=" ";" fSemi "${f}")
      list(GET fSemi 0 CPPTEST_LINK_NAME)
      list(GET fSemi 1 CPPTEST_LINK_TARGET)
      
      configure_file(
        ${_THIS_MODULE_TEMPLATES_DIR}/linked_folder.in
        ${CMAKE_CURRENT_BINARY_DIR}/${CPPTEST_LINK_NAME}.linked_folder @ONLY
        NEWLINE_STYLE UNIX)
      file(STRINGS ${CMAKE_CURRENT_BINARY_DIR}/${CPPTEST_LINK_NAME}.linked_folder fLinked)
      string(APPEND CPPTEST_LINKED_FOLDERS "\n" ${fLinked})
      
      file(MAKE_DIRECTORY ${CPPTEST_LINK_TARGET})
    endforeach()
  endif()

  configure_file(
    ${_THIS_MODULE_TEMPLATES_DIR}/project.in
    ${CPPTEST_PROJECT_LOC}/.project @ONLY
    NEWLINE_STYLE UNIX)

  # Prefix C++ compiler with cpptestscan
  set_target_properties(${TARGET} PROPERTIES
    CXX_COMPILER_LAUNCHER
    ${CMAKE_CURRENT_BINARY_DIR}/${OPTSCAN_NAME}
  )

  # Prefix C compiler with cpptestscan
  set_target_properties(${TARGET} PROPERTIES
    C_COMPILER_LAUNCHER
    ${CMAKE_CURRENT_BINARY_DIR}/${OPTSCAN_NAME}
  )

  # Prefix linker with cpptestscan
  set_target_properties(${TARGET} PROPERTIES
    RULE_LAUNCH_LINK
    ${CMAKE_CURRENT_BINARY_DIR}/${OPTSCAN_NAME}
  )

  # For compatibility with older CMake versions:
  # set_target_properties(${TARGET} PROPERTIES
  #   RULE_LAUNCH_COMPILE
  #   ${CMAKE_CURRENT_BINARY_DIR}/${OPTSCAN_NAME}
  # )

  # Set up cleaning generated CPPTEST_BDF file
  # - since cmake 3.15
  set_target_properties(${TARGET} PROPERTIES
    ADDITIONAL_CLEAN_FILES
    ${CPPTEST_BDF}
  )
  # For cmake < 3.15, works only with Makefile generator
  set_directory_properties(
    PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES
    ${CPPTEST_BDF}
  )

endfunction()
