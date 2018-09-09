#!/bin/bash

set -e

echo "Deleting derived data"
rm -rf dd/

echo "Building for testing. Refer xcodebuild.log.ignored for logs."
xcodebuild build-for-testing \
-scheme "TestApp" \
-derivedDataPath "$(pwd)/dd" \
-destination "platform=iOS Simulator,name=iPhone SE,OS=10.3.1" \
&> xcodebuild.log.ignored

# Work around a bug when xcodebuild puts Build and Indexes folders to a pwd instead of dd/

[ -d "Build" ] && echo "Moving Build/ -> dd/" && mv -f "Build" "dd"
[ -d "Index" ] && echo "Moving Index/ -> dd/" && mv -f "Index" "dd"

echo "Done"
