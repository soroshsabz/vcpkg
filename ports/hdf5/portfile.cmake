if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    message(FATAL_ERROR "${PORT} does not currently support UWP")
endif()

include(vcpkg_common_functions)

vcpkg_download_distfile(ARCHIVE
    URLS "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/CMake-hdf5-1.10.5.zip"
    FILENAME "CMake-hdf5-1.10.5.zip"
    SHA512 d799ae987d00f493a0a0a2c9f61beaa1a5a1dfd18509e310bd7eb2b3bb411d337fbff5f7f8cc58d0708ba2542d8831fec1ae1adc0f845b3d3579809ec7edc4e0
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF hdf5
    PATCHES
        hdf5_config.patch
)
set(SOURCE_PATH ${SOURCE_PATH}/hdf5-1.10.5)

if ("parallel" IN_LIST FEATURES)
    set(ENABLE_PARALLEL ON)
else()
    set(ENABLE_PARALLEL OFF)
endif()

if ("cpp" IN_LIST FEATURES)
    set(ENABLE_CPP ON)
else()
    set(ENABLE_CPP OFF)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DBUILD_TESTING=OFF
        -DHDF5_BUILD_EXAMPLES=OFF
        -DHDF5_BUILD_TOOLS=OFF
        -DHDF5_BUILD_CPP_LIB=${ENABLE_CPP}
        -DHDF5_ENABLE_PARALLEL=${ENABLE_PARALLEL}
        -DHDF5_ENABLE_Z_LIB_SUPPORT=ON
        -DHDF5_ENABLE_SZIP_SUPPORT=ON
        -DHDF5_ENABLE_SZIP_ENCODING=ON
        -DHDF5_INSTALL_DATA_DIR=share/hdf5/data
        -DHDF5_INSTALL_CMAKE_DIR=share/
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(RENAME ${CURRENT_PACKAGES_DIR}/share/hdf5/data/COPYING ${CURRENT_PACKAGES_DIR}/share/hdf5/copyright)

vcpkg_fixup_cmake_targets(CONFIG_PATH share/hdf5)

# Fix static szip link
file(READ ${CURRENT_PACKAGES_DIR}/share/hdf5/hdf5-targets.cmake HDF5_TARGETS_DATA)
# Fix szip linkage
STRING(REPLACE LINK_ONLY:szip-static [[LINK_ONLY:${_IMPORT_PREFIX}/$<$<CONFIG:Debug>:debug/>lib/libszip$<$<CONFIG:Debug>:_D>.lib]] HDF5_TARGETS_NEW "${HDF5_TARGETS_DATA}")
# Fix zlib linkage
STRING(REPLACE "lib/zlib.lib" [[$<$<CONFIG:Debug>:debug/>lib/zlib$<$<CONFIG:Debug>:d>.lib]] HDF5_TARGETS_NEW "${HDF5_TARGETS_NEW}")

#write everything to file
file(WRITE ${CURRENT_PACKAGES_DIR}/share/hdf5/hdf5-targets.cmake "${HDF5_TARGETS_NEW}")

#Linux build create additional scripts here. I dont know what they are doing so I am deleting them and hope for the best 
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
