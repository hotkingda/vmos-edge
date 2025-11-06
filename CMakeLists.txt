cmake_minimum_required(VERSION 3.21)

# set(VCPKG_TARGET_ARCHITECTURE x64 arm64)
# set(VCPKG_OSX_ARCHITECTURES x64 arm64)
# set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64" CACHE STRING "Build architectures for macOS" FORCE)
# set(CMAKE_TOOLCHAIN_FILE /Users/xskj/Documents/develop_tools/vcpkg/scripts/buildsystems/vcpkg.cmake)
# include(/Users/xskj/Documents/develop_tools/vcpkg/scripts/buildsystems/vcpkg.cmake)
# if(LINUX)
#     set(CMAKE_TOOLCHAIN_FILE /home/xianghong/vcpkg/scripts/buildsystems/vcpkg.cmake)
# elseif(WIN32)
#     set(CMAKE_TOOLCHAIN_FILE D:/develop/vcpkg/scripts/buildsystems/vcpkg.cmake)
# elseif(APPLE)
#     set(CMAKE_TOOLCHAIN_FILE /Users/xskj/Documents/develop_tools/vcpkg/scripts/buildsystems/vcpkg.cmake)
# endif()

project(vmosedge VERSION 1.0)

if (MSVC)
    #让Release也生成pdb文件
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
endif ()

set(APP_NAME "VMOSCloud")

# 设置输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE})

# 设置QSC_DEPLOY_PATH，供QtScrcpyCore使用
if(APPLE)
    set(APPLICATION_DIR_PATH ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.app/Contents/MacOS)
else()
    set(APPLICATION_DIR_PATH ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
endif()
set(QSC_DEPLOY_PATH ${APPLICATION_DIR_PATH})

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Gui)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui)

# add_subdirectory(armcloud_pc_sdk)
add_subdirectory(FluentUI)
add_subdirectory(QtScrcpyCore)
add_subdirectory(src)
# add_subdirectory(aliyun-oss-cpp-sdk)
