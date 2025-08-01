#!/bin/sh
#
#    jcd
#
#    Copyright (c) Microsoft Corporation
#
#    All rights reserved.
#
#    MIT License
#
#    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#################################################################################
#
# makePackages.sh
#
# Builds the directory trees for DEB and RPM packages and, if suitable tools are
# available, builds the actual packages too.
#
#################################################################################

if [ "$5" = "" ]; then
    echo "Usage: $0 <SourceDir> <BinaryDir> <package name> <package version> <package release> <PackageType> <architecture>"
    exit 1
fi

# copy cmake vars
CMAKE_SOURCE_DIR=$1
PROJECT_BINARY_DIR=$2
PACKAGE_NAME=$3
PACKAGE_VER=$4
PACKAGE_REL=$5
PACKAGE_TYPE=$6
ARCHITECTURE=$7

DEB_PACKAGE_NAME="${PACKAGE_NAME}_${PACKAGE_VER}_${ARCHITECTURE}"
RPM_PACKAGE_NAME="${PACKAGE_NAME}-${PACKAGE_VER}-${PACKAGE_REL}"
BREW_PACKAGE_NAME="${PACKAGE_NAME}-mac-${PACKAGE_VER}"

if [ "$PACKAGE_TYPE" = "deb" ]; then
    DPKGDEB=`which dpkg-deb`

    if [ -d "${PROJECT_BINARY_DIR}/deb" ]; then
        rm -rf "${PROJECT_BINARY_DIR}/deb"
    fi

    # copy deb files
    mkdir -p "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}"
    sed -e "s/@PROJECT_VERSION_MAJOR@.@PROJECT_VERSION_MINOR@.@PROJECT_VERSION_PATCH@/$PACKAGE_VER/" -e "s/@ARCHITECTURE@/$ARCHITECTURE/" "${CMAKE_SOURCE_DIR}/dist/DEBIAN.in/control.in" > "${PROJECT_BINARY_DIR}/DEBIANcontrol"
    mkdir -p "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/DEBIAN"
    cp "${PROJECT_BINARY_DIR}/DEBIANcontrol" "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/DEBIAN/control"
    mkdir -p "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/usr/bin"
    cp "${PROJECT_BINARY_DIR}/jcd" "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/usr/bin/"
    cp "${PROJECT_BINARY_DIR}/jcd_function.sh" "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/usr/bin/"
    chmod 755 "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/usr/bin/jcd"
    chmod 755 "${PROJECT_BINARY_DIR}/deb/${DEB_PACKAGE_NAME}/usr/bin/jcd_function.sh"

    # make the deb
    if [ "$DPKGDEB" != "" ]; then
        cd "${PROJECT_BINARY_DIR}/deb"
        "$DPKGDEB" -Zxz --build --root-owner-group "${DEB_PACKAGE_NAME}"
        RET=$?
    else
        echo "No dpkg-deb found"
        RET=1
    fi

    exit 0
fi

if [ "$PACKAGE_TYPE" = "rpm" ]; then
    RPMBUILD=`which rpmbuild`

    if [ -d "${PROJECT_BINARY_DIR}/rpm" ]; then
        rm -rf "${PROJECT_BINARY_DIR}/rpm"
    fi

    # copy rpm files
    mkdir -p "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}/SPECS"
    sed -e "s/@PROJECT_VERSION_MAJOR@.@PROJECT_VERSION_MINOR@.@PROJECT_VERSION_PATCH@/$PACKAGE_VER/" -e "s/@PROJECT_VERSION_TWEAK@/0/" "${CMAKE_SOURCE_DIR}/dist/SPECS.in/spec.in" > "${PROJECT_BINARY_DIR}/SPECS.spec"
    cp -a "${PROJECT_BINARY_DIR}/SPECS.spec" "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}/SPECS/${RPM_PACKAGE_NAME}.spec"
    mkdir "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}/BUILD/"
    echo "HELLO"${CMAKE_SOURCE_DIR}
    cp "${CMAKE_SOURCE_DIR}/${PROJECT_BINARY_DIR}/jcd" "${CMAKE_SOURCE_DIR}/${PROJECT_BINARY_DIR}/jcd_function.sh" "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}/BUILD/"
    chmod 755 "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}/BUILD/jcd"
    chmod 755 "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}/BUILD/jcd_function.sh"

    # make the rpm
    if [ "$RPMBUILD" != "" ]; then
        cd "${PROJECT_BINARY_DIR}/rpm/${RPM_PACKAGE_NAME}"
        "$RPMBUILD" --define "_topdir `pwd`" -v -bb "SPECS/${RPM_PACKAGE_NAME}.spec"
        RET=$?
        cp RPMS/$(uname -m)/*.rpm ..
    else
        echo "No rpmbuild found"
        RET=1
    fi
fi

if [ "$PACKAGE_TYPE" = "brew" ]; then

    # create brew package
    zip $PROJECT_BINARY_DIR/${BREW_PACKAGE_NAME}.zip $PROJECT_BINARY_DIR/jcd $PROJECT_BINARY_DIR/jcd_function.sh
fi
exit $RET