set -e

avitoRunnerBinaryPath="$(pwd)/.build/x86_64-apple-macosx10.10/debug/AvitoRunner"
echo "Assuming avito runner has been built already and available at: '$avitoRunnerBinaryPath'"

testPluginBundlePath="$(pwd)/TestPlugin/.build/debug/TestPlugin.emceeplugin"
echo "Assuming test plugin has been built already and available at: '$testPluginBundlePath'"

echo "Installing pytest"
pip3 install pytest

echo "Building test app"
tempfolder="$(pwd)/auxiliary/tempfolder"
derivedDataPath="$tempfolder"
xcodebuildLogPath="$derivedDataPath/xcodebuild.log.ignored"
echo "Deleting derived data at $derivedDataPath"
rm -rf "$derivedDataPath"
mkdir -p "$derivedDataPath"

echo "Building for testing. Build is log path: $xcodebuildLogPath"
cd TestApp/
xcodebuild build-for-testing \
-scheme "TestApp" \
-derivedDataPath "$derivedDataPath" \
-destination "platform=iOS Simulator,name=iPhone SE,OS=10.3.1" \
&> "$xcodebuildLogPath"
cd -

# Work around a bug when xcodebuild puts Build and Indexes folders to a pwd instead of dd/

[ -d "Build" ] && echo "Moving Build/ -> $derivedDataPath/" && mv -f "Build" "$derivedDataPath"
[ -d "Index" ] && echo "Moving Index/ -> $derivedDataPath/" && mv -f "Index" "$derivedDataPath"

echo "Running integration tests"

"$avitoRunnerBinaryPath" runTests \
--app "$derivedDataPath/Build/Products/Debug-iphonesimulator/TestApp.app" \
--environment "auxiliary/environment.json" \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbsimctl_20180831T142903.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbxctest_20180831T142535.zip" \
--junit "$tempfolder/test-results/junit.combined.xml" \
--number-of-retries 1 \
--number-of-simulators 2 \
--plugin "$testPluginBundlePath" \
--runner "$derivedDataPath/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app" \
--schedule-strategy "individual" \
--single-test-timeout 100 \
--temp-folder "$derivedDataPath" \
--test-destinations "auxiliary/destination_iphone_se_ios103.json" \
--trace "$tempfolder/test-results/trace.combined.json" \
--xctest-bundle "$derivedDataPath/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app/PlugIns/TestAppUITests.xctest"

echo "Analyzing test results"
pytest "auxiliary/test_run_results.py"

rm -rf "$tempfolder"
