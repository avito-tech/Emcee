#!/bin/bash

cd "$(dirname "$0")"

set -xueo pipefail

EMCEE_COMMIT_HASH=$(git rev-parse HEAD)
EMCEE_SHORT_VERSION="${EMCEE_COMMIT_HASH:0:7}"

function install_deps() {
	brew ls --versions pkg-config > /dev/null || brew install pkg-config
	brew ls --versions libssh2 > /dev/null || brew install libssh2
 
    if [[ ! -h $(brew --prefix)/lib/pkgconfig/openssl.pc ]]; then
        ln -s $(brew --prefix)/opt/openssl@1.1/lib/pkgconfig/openssl.pc $(brew --prefix)/lib/pkgconfig/openssl.pc
    fi
    
    if [[ ! -h $(brew --prefix)/lib/pkgconfig/libssl.pc ]]; then
        ln -s $(brew --prefix)/opt/openssl@1.1/lib/pkgconfig/libssl.pc $(brew --prefix)/lib/pkgconfig/libssl.pc
    fi
    
    if [[ ! -h $(brew --prefix)/lib/pkgconfig/libcrypto.pc ]]; then
        ln -s $(brew --prefix)/opt/openssl@1.1/lib/pkgconfig/libcrypto.pc $(brew --prefix)/lib/pkgconfig/libcrypto.pc
    fi
    
    swift package resolve
}

function generate_package_swift() {
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

function open_xcodeproj() {
	generate_xcodeproj
	open *.xcodeproj
}

function generate_xcodeproj() {
	install_deps
    generate_package_swift
	swift package generate-xcodeproj --enable-code-coverage
}

function clean() {
	rm -rf .build/
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
    generate)
        generate_xcodeproj
        ;;
    open)
    	open_xcodeproj
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
