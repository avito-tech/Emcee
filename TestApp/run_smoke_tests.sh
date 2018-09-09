echo "Building avito runner"
cd ../
make build
cd -

echo "Building test app"
./build_test_app.sh

echo "Running tests"

avitoRunnerBinaryPath="../.build/x86_64-apple-macosx10.10/debug/AvitoRunner"
tempFolderPath="$(pwd)/tempfolder/"

"$avitoRunnerBinaryPath" runTests \
--fbsimctl "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbsimctl_20180831T142903.zip" \
--fbxctest "https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.1/fbxctest_20180831T142535.zip" \
--junit "$(pwd)/test-results/junit.combined.xml" \
--trace "$(pwd)/test-results/trace.combined.json" \
--number-of-retries 1 \
--number-of-simulators 2 \
--app "$(pwd)/dd/Build/Products/Debug-iphonesimulator/TestApp.app" \
--runner "$(pwd)/dd/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app" \
--xctest-bundle "$(pwd)/dd/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app/PlugIns/TestAppUITests.xctest" \
--schedule-strategy "individual" \
--single-test-timeout 100 \
--temp-folder "$tempFolderPath" \
--test-destinations "destination_iphone_se_ios103.json"

echo "Deleting: $tempFolderPath"
rm -rf "$tempFolderPath"

pip install pytest
pytest "analyze_results.py"
