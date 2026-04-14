cmake_minimum_required(VERSION 3.21)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_ARCHITECTURES "arm64")

project(iOS120Hz VERSION 1.0.0)

# Find Geode SDK via environment variable
if (NOT DEFINED ENV{GEODE_SDK})
    message(FATAL_ERROR "Unable to find Geode SDK! Please define GEODE_SDK environment variable to point to Geode")
else()
    message(STATUS "Found Geode: $ENV{GEODE_SDK}")
endif()

add_subdirectory($ENV{GEODE_SDK} ${CMAKE_CURRENT_BINARY_DIR}/geode)

# Create the mod
add_library(${PROJECT_NAME} MODULE
    src/main.mm
)

# Link frameworks needed for iOS display
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    target_link_libraries(${PROJECT_NAME} PRIVATE
        "-framework QuartzCore"
        "-framework UIKit"
        "-framework Foundation"
    )
endif()

# Create Geode mod (links geode-sdk automatically)
setup_geode_mod(${PROJECT_NAME})
