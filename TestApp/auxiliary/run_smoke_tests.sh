set -e

echo "Building avito runner"

# let's work from within the root folder of TestApp
cd ../
make build
cd -

echo "Building test app"
derivedDataPath="$(pwd)/auxiliary/tempfolder"
echo "Deleting derived data at $derivedDataPath"
rm -rf "$derivedDataPath"

echo "Building for testing. Refer xcodebuild.log.ignored for logs."
xcodebuild build-for-testing \
-scheme "TestApp" \
-derivedDataPath "$derivedDataPath" \
-destination "platform=iOS Simulator,name=iPhone SE,OS=10.3.1" \
&> xcodebuild.log.ignored

# Work around a bug when xcodebuild puts Build and Indexes folders to a pwd instead of dd/

[ -d "Build" ] && echo "Moving Build/ -> $derivedDataPath/" && mv -f "Build" "$derivedDataPath"
[ -d "Index" ] && echo "Moving Index/ -> $derivedDataPath/" && mv -f "Index" "$derivedDataPath"

echo "Running integration tests"
avitoRunnerBinaryPath="../.build/x86_64-apple-macosx10.10/debug/AvitoRunner"
testPluginBundlePath=`realpath $(pwd)/../TestPlugin/.build/debug/TestPlugin.emceeplugin`

"$avitoRunnerBinaryPath" runTests \
--app "$derivedDataPath/Build/Products/Debug-iphonesimulator/TestApp.app" \
--environment "auxiliary/environment.json" \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbsimctl_20180831T142903.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbxctest_20180831T142535.zip" \
--junit "$(pwd)/test-results/junit.combined.xml" \
--number-of-retries 1 \
--number-of-simulators 2 \
--plugin "$testPluginBundlePath" \
--runner "$derivedDataPath/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app" \
--schedule-strategy "individual" \
--single-test-timeout 100 \
--temp-folder "$derivedDataPath" \
--test-destinations "auxiliary/destination_iphone_se_ios103.json" \
--trace "$(pwd)/test-results/trace.combined.json" \
--xctest-bundle "$derivedDataPath/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app/PlugIns/TestAppUITests.xctest"

rm -rf "$derivedDataPath"

echo "Analyzing test results"
pip3 install pytest
pytest "auxiliary/test_run_results.py"

rm -rf "test-results"
