#!/bin/bash

set -e

echo "Deleting derived data"
rm -rf dd/

echo "Building for testing. Refer xcodebuild.log.ignored for logs."
xcodebuild \
build-for-testing \
-scheme TestApp \
-derivedDataPath dd \
-destination "platform=iOS Simulator,name=iPhone SE,OS=10.3.1" \
&> xcodebuild.log.ignored

echo "Done"
