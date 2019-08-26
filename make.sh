#!/bin/bash

cd "$(dirname "$0")"

set -x

function expose_required_developer_dir() {
	required_xcode_version=$1

	savedIFS=$IFS
	IFS=$'\n'
	for xcode_path in $(mdfind -onlyin /Applications "kMDItemCFBundleIdentifier = com.apple.dt.Xcode")
	do
		xcode_version=$(defaults read "$xcode_path/Contents/Info.plist" CFBundleShortVersionString)
		if [[ $xcode_version == $required_xcode_version ]]
		then
			DEVELOPER_DIR="$xcode_path/Contents/Developer"
			echo "Found Xcode with version $required_xcode_version at: $DEVELOPER_DIR"
			return 0
		fi
	done
	IFS=$savedIFS
	
	echo "ERROR: can't locate Xcode with version: '$required_xcode_version'"
	exit 1
}

function install_deps() {
	brew ls --versions pkg-config > /dev/null || brew install pkg-config
	brew ls --versions libssh2 > /dev/null || brew install libssh2
}

function open_xcodeproj() {
	generate_xcodeproj
	open *.xcodeproj
}

function generate_xcodeproj() {
	install_deps
	DEVELOPER_DIR="$DEVELOPER_DIR" swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig --enable-code-coverage
}

function clean() {
	rm -rf .build/
	rm -rf SamplePlugin/.build/
}

function build() {
	install_deps
	DEVELOPER_DIR="$DEVELOPER_DIR" swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13"
}

function run_tests_parallel() {
	install_deps
	DEVELOPER_DIR="$DEVELOPER_DIR" swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --parallel
}

function run_integration_tests() {
	install_deps
	echo "Integration tests have been removed"
}

case "$1" in
    generate)
        generate_xcodeproj
        ;;
    open)
    	open_xcodeproj
    	;;
    test)
        run_tests_parallel
        ;;
	integration-test)
        run_integration_tests
        ;;
    build)
    	build
    	;;
    clean)
    	clean
    	;;
esac
