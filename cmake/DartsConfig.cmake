# ============================================================================
# Include guards
# ============================================================================

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(
    FATAL_ERROR
      "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there."
  )
endif()

# ============================================================================
# Optional features available to users
# ============================================================================
option(USE_NANOVDB "Include nanovdb support?" OFF)
option(USE_FLIP "Include support for the FLIP image comparison tool?" OFF)

message(STATUS "NANOVDB support is: ${USE_NANOVDB}")
message(STATUS "FLIP support is: ${USE_FLIP}")

# ============================================================================
# Set a default build configuration (Release)
# ============================================================================
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      Release
      CACHE STRING "Choose the type of build." FORCE
  )
  set_property(
    CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo"
  )
endif()
string(TOUPPER "${CMAKE_BUILD_TYPE}" U_CMAKE_BUILD_TYPE)

# ============================================================================
# compile the rest of the codebase using C++17
# ============================================================================
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set directory for build products
if(MSVC)
  # MSVC: .. with generator expression for build type
  set(DARTS_BINARY_DIR ${PROJECT_BINARY_DIR}/$<CONFIG>)
else()
  set(DARTS_BINARY_DIR ${PROJECT_BINARY_DIR})
endif()

# Avoid macro hell from windows.h
if(WIN32)
  add_definitions(-DWIN32_LEAN_AND_MEAN -DNOMINMAX -DNOGDI -DVC_EXTRALEAN)
endif()

set(DARTS_DEPEND)
set(DARTS_PRIVATE_LIBS)
set(DARTS_PUBLIC_LIBS)

# ============================================================================
# Add dependencies via CPM (cmake/tools.cmake includes cmake/CPM.cmake)
#
# see https://github.com/TheLartians/CPM.cmake for more info
# ============================================================================
include(cmake/tools.cmake)

CPMAddPackage(
  NAME nlohmann_json
  VERSION 3.11.2 # the git repo is incredibly large, so we download the archived include directory
  URL https://github.com/nlohmann/json/releases/download/v3.11.2/include.zip
  DOWNLOAD_ONLY YES DOWNLOAD_EXTRACT_TIMESTAMP NO
)
if(nlohmann_json_ADDED)
  add_library(nlohmann_json INTERFACE IMPORTED)
  target_include_directories(nlohmann_json INTERFACE ${nlohmann_json_SOURCE_DIR}/single_include)
  list(APPEND DARTS_PUBLIC_LIBS nlohmann_json)
endif()

CPMAddPackage(
  NAME filesystem
  GITHUB_REPOSITORY wkjarosz/filesystem
  GIT_TAG 5e0eb2a6160201de38d076c085641742ee86a8f6
  DOWNLOAD_ONLY YES
)
if(filesystem_ADDED)
  add_library(filesystem INTERFACE IMPORTED)
  target_include_directories(filesystem INTERFACE "${filesystem_SOURCE_DIR}")
  list(APPEND DARTS_PUBLIC_LIBS filesystem)
endif()

CPMAddPackage("gh:nothings/stb#a0a939058c579ddefd4c5671b046f29d12aeae01")
if(stb_ADDED)
  add_library(stb INTERFACE IMPORTED)
  target_include_directories(stb INTERFACE "${stb_SOURCE_DIR}")
  list(APPEND DARTS_PRIVATE_LIBS stb)
endif()

CPMAddPackage(
  NAME fmt
  URL https://github.com/fmtlib/fmt/archive/refs/tags/9.1.0.zip
  # GITHUB_REPOSITORY fmtlib/fmt GIT_TAG 02ad5e11da5b2702cc1c9a8fdf750486beee08fe
  OPTIONS "FMT_INSTALL NO" # create an installable target
  # DOWNLOAD_ONLY YES
)

CPMAddPackage("gh:sgorsten/linalg#4460f1f5b85ccc81ffcf49aa450d454db58ca90e")
if(linalg_ADDED)
  add_library(linalg INTERFACE IMPORTED)
  target_include_directories(linalg INTERFACE "${linalg_SOURCE_DIR}")
  list(APPEND DARTS_PUBLIC_LIBS linalg)
endif()

CPMAddPackage(
  NAME cli11
  URL https://github.com/CLIUtils/CLI11/archive/v1.9.1.zip
  DOWNLOAD_ONLY YES DOWNLOAD_EXTRACT_TIMESTAMP NO
)
if(cli11_ADDED)
  add_library(cli11 INTERFACE IMPORTED)
  target_include_directories(cli11 INTERFACE "${cli11_SOURCE_DIR}/include")
  list(APPEND DARTS_PUBLIC_LIBS cli11)
endif()

CPMAddPackage(
  NAME tinyobjloader
  GITHUB_REPOSITORY tinyobjloader/tinyobjloader
  GIT_TAG a4e519b0a0f29c790464fcfeadfe25a7f9fa15ff
  DOWNLOAD_ONLY YES
)
if(tinyobjloader_ADDED)
  add_library(tinyobjloader INTERFACE IMPORTED)
  target_include_directories(tinyobjloader INTERFACE "${tinyobjloader_SOURCE_DIR}/")
  list(APPEND DARTS_PRIVATE_LIBS tinyobjloader)
endif()

CPMAddPackage(
  NAME tinyexr
  GITHUB_REPOSITORY syoyo/tinyexr
  VERSION 1.0.12
  # the git repo is incredibly large, so we download the archived include directory
  URL https://github.com/syoyo/tinyexr/archive/refs/tags/v1.0.12.zip
  # OPTIONS "TINYEXR_BUILD_SAMPLE OFF"
  DOWNLOAD_ONLY YES
)
if(tinyexr_ADDED)
  add_library(
    miniz "${tinyexr_SOURCE_DIR}/deps/miniz/miniz.c" "${tinyexr_SOURCE_DIR}/deps/miniz/miniz.h"
  )
  target_include_directories(miniz PUBLIC ${tinyexr_SOURCE_DIR}/deps/miniz/)
  list(APPEND DARTS_DEPEND miniz)
  list(APPEND DARTS_PRIVATE_LIBS miniz)

  add_library(tinyexr INTERFACE IMPORTED)
  # target_compile_features(tinyexr PRIVATE cxx_std_11)
  target_include_directories(tinyexr INTERFACE ${tinyexr_SOURCE_DIR}/)
  add_dependencies(tinyexr miniz)
  list(APPEND DARTS_PRIVATE_LIBS tinyexr)
endif()

CPMAddPackage(
  NAME spdlog
  URL https://github.com/gabime/spdlog/archive/refs/tags/v1.11.0.zip
  OPTIONS "SPDLOG_INSTALL NO" # create an installable target
          "SPDLOG_FMT_EXTERNAL YES" # use the fmt library we added above instead of the bundled one
)
if(spdlog_ADDED)
  list(APPEND DARTS_DEPEND spdlog)
  list(APPEND DARTS_PUBLIC_LIBS spdlog::spdlog)
endif()

# cmake-format: off
# # Add OpenImageDenoise as a subproject
# CPMAddPackage(
#   NAME OpenImageDenoise
#   GITHUB_REPOSITORY renderkit/oidn
#   VERSION 2.3.1
# )
# if(OpenImageDenoise_ADDED)
#   list(APPEND DARTS_DEPEND OpenImageDenoise)
#   list(APPEND DARTS_PUBLIC_LIBS OpenImageDenoise)
# endif()
# cmake-format: on

CPMAddPackage("gh:wkjarosz/smallthreadpool#386dc5d7d5eaf60cb00b34345170548a0c0f3ef9")
if(smallthreadpool_ADDED)
  add_library(smallthreadpool INTERFACE IMPORTED)
  target_include_directories(smallthreadpool INTERFACE "${smallthreadpool_SOURCE_DIR}/")
  list(APPEND DARTS_DEPEND smallthreadpool)
  list(APPEND DARTS_PUBLIC_LIBS smallthreadpool)
endif()

if(USE_NANOVDB)
  # windows doesn't have zlib, which is necessary for NanoVDB
  if(WIN32)
    CPMAddPackage(
      NAME zlibstatic
      GIT_REPOSITORY https://github.com/mitsuba-renderer/zlib.git
      GIT_TAG 080a732c47e86444034c1f99355368d35c1e458a
      OPTIONS "ZLIB_BUILD_STATIC_LIBS TRUE" "ZLIB_BUILD_SHARED_LIBS FALSE" EXCLUDE_FROM_ALL
    )
    if(zlibstatic_ADDED)
      get_target_property(zstype zlibstatic TYPE)
      message(STATUS "ZLIB library type: ${zstype}")
      set(ZLIB_INCLUDE_DIR
          ${zlibstatic_SOURCE_DIR} ${zlibstatic_BINARY_DIR}
          CACHE PATH " " FORCE
      )
      set(ZLIB_LIBRARY zlibstatic)
      set(ZLIB_FOUND TRUE)
      message(STATUS "Adding zlib includes: ${ZLIB_INCLUDE_DIR}")

      add_library(ZLIB::ZLIB ALIAS zlibstatic)
      list(APPEND DARTS_DEPEND zlibstatic)
    endif()
  endif()

  CPMAddPackage(
    NAME openvdb
    URL https://github.com/AcademySoftwareFoundation/openvdb/archive/refs/tags/v9.1.0.zip
    OPTIONS "OPENVDB_BUILD_CORE OFF"
            "OPENVDB_BUILD_BINARIES OFF"
            "USE_NANOVDB ON"
            "NANOVDB_ALLOW_FETCHCONTENT ON"
            "NANOVDB_USE_ZLIB ON"
            "NANOVDB_BUILD_TOOLS OFF"
            "NANOVDB_USE_TBB OFF"
            "NANOVDB_USE_OPENVDB OFF"
            "NANOVDB_USE_BLOSC OFF"
            "NANOVDB_USE_CUDA OFF"
            "NANOVDB_USE_OPTIX OFF"
            "NANOVDB_USE_OPENCL OFF"
  )
  if(openvdb_ADDED)
    get_target_property(type nanovdb TYPE)
    message(STATUS "NanoVDB library type: ${type}")
    if(zlibstatic_ADDED)
      message(STATUS "Adding zlib dependency to nanovdb")
      add_dependencies(nanovdb zlibstatic)
      target_include_directories(nanovdb INTERFACE ${ZLIB_INCLUDE_DIR})
      list(APPEND DARTS_DEPEND nanovdb)
    endif()
    list(APPEND DARTS_PRIVATE_LIBS nanovdb)
  endif()
endif()

if(USE_FLIP)
  include(FetchContent)
  FetchContent_Declare(
    flip
    GIT_REPOSITORY https://github.com/NVlabs/flip.git
    GIT_TAG c13d9701b8a6dd4e3725ab0fcac775f9b91e3480
  )

  message(STATUS "Adding FLIP image comparison tool")
  FetchContent_MakeAvailable(flip)
endif()

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
list(APPEND DARTS_PRIVATE_LIBS Threads::Threads)

# Set up location for build products
set_target_properties(
  ${DARTS_DEPEND}
  PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${DARTS_BINARY_DIR}
             LIBRARY_OUTPUT_DIRECTORY ${DARTS_BINARY_DIR}
             RUNTIME_OUTPUT_DIRECTORY_RELEASE ${DARTS_BINARY_DIR}
             LIBRARY_OUTPUT_DIRECTORY_RELEASE ${DARTS_BINARY_DIR}
             RUNTIME_OUTPUT_DIRECTORY_DEBUG ${DARTS_BINARY_DIR}
             LIBRARY_OUTPUT_DIRECTORY_DEBUG ${DARTS_BINARY_DIR}
             RUNTIME_OUTPUT_DIRECTORY_RELNODEBINFO ${DARTS_BINARY_DIR}
             LIBRARY_OUTPUT_DIRECTORY_RELNODEBINFO ${DARTS_BINARY_DIR}
             RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${DARTS_BINARY_DIR}
             LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL ${DARTS_BINARY_DIR}
)
