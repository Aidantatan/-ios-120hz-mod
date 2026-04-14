cmake_minimum_required(VERSION 3.21)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_ARCHITECTURES "arm64")

project(iOS120Hz VERSION 1.0.0)

# Find Geode
find_package(Geode REQUIRED)

# Create the mod
add_library(${PROJECT_NAME} SHARED
    src/main.mm
)

# Link frameworks needed for iOS display
if(IOS)
    target_link_libraries(${PROJECT_NAME} PRIVATE
        "-framework QuartzCore"
        "-framework UIKit"
        "-framework Foundation"
    )
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE Geode::Geode)

# Create Geode mod
setup_geode_mod(${PROJECT_NAME})
