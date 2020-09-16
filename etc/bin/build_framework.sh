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

SIMULATOR_ARCHIVE_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.xcarchive"

DEVICE_ARCHIVE_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.xcarchive"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"

######################
# Build Frameworks
######################

xcodebuild archive -project ${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj -scheme ${FRAMEWORK_NAME} -destination="iOS Simulator" -archivePath "${SIMULATOR_ARCHIVE_PATH}" -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

xcodebuild archive -project ${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj -scheme ${FRAMEWORK_NAME} -destination="iOS" -archivePath "${DEVICE_ARCHIVE_PATH}" -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

######################
# Create directory for universal
######################

rm -rf "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${UNIVERSAL_LIBRARY_DIR}"

######################
# Make an xcframework
######################

xcodebuild -create-xcframework -framework "${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" -framework "${DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" -output "${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.xcframework" | echo

######################
# On Release, copy the result to release directory
######################

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.xcframework" "$OUTPUT_DIR"
cp "$PROJECT_DIR/../LICENSE.TXT" "$OUTPUT_DIR"
cp "$PROJECT_DIR/../README.md" "$OUTPUT_DIR"
cp "$PROJECT_DIR/../CHANGELOG.md" "$OUTPUT_DIR"

VERSION=`cat Apptentive/Apptentive/ApptentiveMain.h | sed -n -e 's/#define kApptentiveVersionString @"\([^"]*\)"/\1/p'`

pushd "$OUTPUT_DIR"
tar -zcv -f "../apptentive_ios_framework-$VERSION.tar.gz" .
popd

if [ ${REVEAL_ARCHIVE_IN_FINDER} = true ]; then
open "${OUTPUT_DIR}/"
fi
