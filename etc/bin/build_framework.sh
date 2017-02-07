#!/bin/sh

# Credit: https://medium.com/@syshen/create-an-ios-universal-framework-148eb130a46c

######################
# Options
######################

REVEAL_ARCHIVE_IN_FINDER=true

FRAMEWORK_NAME="Apptentive"
PROJECT_NAME="Apptentive"
CONFIGURATION="Release"
BUILD_DIR="/tmp/apptentive_framework_build"
PROJECT_DIR="Apptentive"
OUTPUT_DIR="${BUILD_DIR}/${FRAMEWORK_NAME}-${CONFIGURATION}-iphoneuniversal/"

SIMULATOR_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"

DEVICE_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"

FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"

######################
# Build Frameworks
######################

xcodebuild -project ${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj -scheme ${FRAMEWORK_NAME} -sdk iphonesimulator -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator ENABLE_BITCODE=YES OTHER_CFLAGS='-fembed-bitcode' GCC_PREPROCESSOR_DEFINITIONS='APPTENTIVE_FRAMEWORK=1' 2>&1

xcodebuild -project ${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj -scheme ${FRAMEWORK_NAME} -sdk iphoneos -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos ENABLE_BITCODE=YES OTHER_CFLAGS='-fembed-bitcode' GCC_PREPROCESSOR_DEFINITIONS='APPTENTIVE_FRAMEWORK=1' 2>&1

######################
# Create directory for universal
######################

rm -rf "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${FRAMEWORK}"

######################
# Copy files Framework
######################

cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"

######################
# Make an universal binary
######################

lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" | echo

######################
# On Release, copy the result to release directory
######################

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "${FRAMEWORK}" "$OUTPUT_DIR"
cp "$PROJECT_DIR/../LICENSE.TXT" "$OUTPUT_DIR"
cp "$PROJECT_DIR/../README.md" "$OUTPUT_DIR"
cp "$PROJECT_DIR/../CHANGELOG.md" "$OUTPUT_DIR"

VERSION=`cat Apptentive/Apptentive/Apptentive.h | sed -n -e 's/#define kApptentiveVersionString @"\([^"]*\)"/\1/p'`

pushd "$OUTPUT_DIR"
tar -zcv -f "../apptentive_ios_framework-$VERSION.tar.gz" .
popd

if [ ${REVEAL_ARCHIVE_IN_FINDER} = true ]; then
open "${OUTPUT_DIR}/"
fi
