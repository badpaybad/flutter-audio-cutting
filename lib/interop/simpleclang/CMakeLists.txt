cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(simpleso_library VERSION 1.0.0 LANGUAGES C)
add_library(simpleso_library SHARED simpleso.c simpleso.def)
add_executable(simpleso_exe simpleso.c)

set_target_properties(simpleso_library PROPERTIES
        PUBLIC_HEADER simpleso.h
        VERSION ${PROJECT_VERSION}
        SOVERSION 1
        OUTPUT_NAME "simpleso"
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
        )