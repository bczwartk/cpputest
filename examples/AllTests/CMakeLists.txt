

add_executable(ExampleTests
    AllTests.cpp
    CircularBufferTest.cpp
    EventDispatcherTest.cpp
    FEDemoTest.cpp
    HelloTest.cpp
    MockDocumentationTest.cpp
    PrinterTest.cpp
)

target_include_directories(ExampleTests
    PRIVATE
        .
        ${CPPTEST_HOME}/runtime/include
)

target_compile_options(ExampleTests
    PRIVATE $<$<BOOL:${MSVC}>:/wd4723>
)

target_compile_definitions(ExampleTests PRIVATE PARASOFT_CPPTEST=1)

target_link_libraries(ExampleTests
    PRIVATE
        ApplicationLib
        CppUTest::CppUTestExt
)
#         ${CPPTEST_HOME}/runtime/build/cpptest.o

if(CPPUTEST_TEST_DISCOVERY OR NOT DEFINED CPPUTEST_TEST_DISCOVERY)
    include(CppUTest)
    cpputest_discover_tests(ExampleTests)
endif()
