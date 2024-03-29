#!/bin/bash

cd "$(dirname "$0")"

set -xueo pipefail

EMCEE_COMMIT_HASH=$(git rev-parse HEAD)
EMCEE_SHORT_VERSION="${EMCEE_COMMIT_HASH:0:7}"

function install_deps() {
	swift package resolve
}

function generate_package_swift() {
    install_deps
    if [[ -d ".build/checkouts/ios-commandlinetoolkit/" ]]
    then
        rm -rf ".build/checkouts/CommandLineToolkit"
        cd ".build/checkouts/"
        ln -s "ios-commandlinetoolkit" "CommandLineToolkit"
        cd -
    fi

    swift run --package-path ".build/checkouts/CommandLineToolkit/PackageGenerator/" package-gen .
}

function generate_emcee_version() {
    sed -i '' -- "s/undefined_version/$EMCEE_SHORT_VERSION/g" "Sources/EmceeVersion/EmceeVersion.swift"
    echo "Replaced source code version from 'undefined_version' with '$EMCEE_SHORT_VERSION'"
}

function reset_emcee_version() {
    sed -i '' -- "s/$EMCEE_SHORT_VERSION/undefined_version/g" "Sources/EmceeVersion/EmceeVersion.swift"
    echo "Reverted source code version '$EMCEE_SHORT_VERSION' to 'undefined_version'"
}

function open_package() {
    generate_package_swift
	open Package.swift
}

function clean() {
	rm -rf .build/
    rm -rf .swiftpm/
	rm -rf *.xcodeproj
}

function build() {
	trap reset_emcee_version EXIT
	generate_emcee_version
	install_deps
    generate_package_swift
	swift build
}

function run_tests_parallel() {
	trap reset_emcee_version EXIT
	generate_emcee_version	
	install_deps
    generate_package_swift
	swift test --parallel
}

case "$1" in
    open)
    	open_package
    	;;
    test)
        run_tests_parallel
        ;;
    build)
    	build
    	;;
    clean)
    	clean
    	;;
    package)
        generate_package_swift
        ;;
esac
