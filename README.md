# Introduction

This project is a proof of concept of how to use MEDFile library from Zig.

**Most of the instructions of this file are dedicated to automatically download,
build and install HDF5 and MEDFile libraries using CMake.**

If you already have a local install of HDF5 and MEDFile, you can directly
run:

```
zig build -Dmedfile-install=$MEDFILE_INSTALL -Dhdf5-install=$HDF5_INSTALL
```

The paths `$MEDFILE_INSTALL` and `$HDF5_INSTALL` **must** be relative, due to
Zig build philosophy (eventhough it is easy to circumvent). 

# Limitation

- Scripts here have only been tested on a x86_64-linux-gnu, Ubuntu 24.04 host.
- If you want to extend using MEDFile in a distributed computation context, Zig's
C-import feature [presently have
issues](https://github.com/lefp/mpi-zig-example) with OpenMPI implementation ,
due to heavy usage of macros inside OpenMPI.
- For unknown reasons, build of HDF5 and MEDFile seems to fail when using clang.
Therefore, scripts in this document enforce usage of gcc.
- Although both MEDFile and HDF5 can be build as static libraries, static
linkage is not attempted here due to possible conflicts with MPI
implementation.


# How to use this makedown document

This document is not an ordinary README file. It's a
[makedown](https://github.com/tzador/makedown). Please refer to the makedown
project documentation to learn how to use it.

# [dependencies]() For Ubuntu 24.04

```
sudo apt install libtirpc-dev cmake gcc libopenmpi-dev
```

# [build-all]() Delete 'deps/' and install everything from scratch

**WARNING:** this command is a convenience when starting from scratch, but is
heavily inefficient for repeated builds.

```
makedown clean-all
makedown build-hdf5
makedown build-medfile
makedown build-example
```

# [clean-all]() Delete 'deps/' directory

```
rm -rf ./deps
```

# [build-hdf5]() Download, then build HDF5 1.10.3 under deps/build and install HDF5 under deps/install

```
version_maj="1"
version_min="10"
version_patch="3"
version="${version_maj}.${version_min}.${version_patch}"

mkdir -p deps/
mkdir -p deps/source
mkdir -p deps/archives

wget "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${version_maj}.${version_min}/hdf5-${version}/src/hdf5-${version}.tar.gz" -O "deps/archives/hdf5-${version}.tar.gz"
tar -C "deps/source" -xf "deps/archives/hdf5-${version}.tar.gz"

mkdir -p deps/install
mkdir -p deps/build

export CC=gcc

cmake --fresh -S "deps/source/hdf5-${version}" -B "deps/build/hdf5-${version}" \
    -DCMAKE_BUILD_TYPE='RelWithDebInfo' \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_INSTALL_PREFIX="deps/install/hdf5-${version}" \
    -DHDF5_ENABLE_PARALLEL=ON \
    -DHDF5_BUILD_CPP_LIB=OFF
ln -sf "../../build/hdf5-${version}/compile_commands.json" "deps/source/hdf5-${version}/compile_commands.json"
cmake --build "deps/build/hdf5-${version}" --parallel "$(nproc)" 
cmake --install "deps/build/hdf5-${version}"
```

# [build-medfile]() Download, then build medfile under deps/build and install medfile under deps/install/

Due to security restrictions, a `User-Agent` trick must be used to download
MEDFile directly from Salome website without using a Web Browser proxy.
The CMake approach is preferred over autotools in order to generate a
`compile_commands.json`.

```
version="4.1.1"

mkdir -p deps
mkdir -p deps/source
mkdir -p deps/archives

wget -c --header="User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
  			--header="Referer: https://www.salome-platform.org/" \
            "https://files.salome-platform.org/Salome/medfile/med-${version}.tar.gz" \
  			-O "deps/archives/med-${version}.tar.gz"
tar -C "deps/source" -xf "deps/archives/med-${version}.tar.gz"

mkdir -p deps/install
mkdir -p deps/build

export CC=gcc
export CXX=g++

cmake --fresh -S "deps/source/med-${version}" -B "deps/build/med-${version}" \
    -DCMAKE_BUILD_TYPE="RelWithDebInfo" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_INSTALL_PREFIX="deps/install/med-${version}" \
    -DHDF5_ROOT_DIR="deps/install/hdf5-1.10.3" \
    -DMED_MEDINT_TYPE="int" \
    -DMEDFILE_USE_MPI="ON" \
    -DMEDFILE_INSTALL_DOC="OFF"
ln -sf "../../build/med-${version}/compile_commands.json" "deps/source/med-${version}/compile_commands.json"
cmake --build "deps/build/med-${version}" --parallel "$(nproc)" 
cmake --install "deps/build/med-${version}" --parallel "$(nproc)" 
```

# [build-example]() Build the example

```
hdf5_version="1.10.3"
med_version="4.1.1"

if ! [ -d "./deps/install/hdf5-${hdf5_version}" ]; then
    echo "Fatal error: it seems that hdf5 has not been installed from the makedown script. Please run 'makedown build-hdf5' or 'makedown build-all'. Abort." >&2
    exit 1
fi
if ! [ -d "./deps/install/med-${med_version}" ]; then
    echo "Fatal error: it seems that medfile has not been installed from the makedown script. Please run 'makedown build-medfile' or 'makedown build-all'. Abort." >&2
    exit 1
fi
zig build --summary all \
    -Dhdf5-install=./deps/install/hdf5-${hdf5_version} \
    -Dmedfile-install=./deps/install/med-${med_version}
```

# [run-example]() Run the example

```
source run.env
./zig-out/bin/main
```
