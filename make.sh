#!/bin/bash

cd "$(dirname "$0")"

set -x

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
	DEVELOPER_DIR="$DEVELOPER_DIR" swift package generate-xcodeproj --enable-code-coverage
}

function clean() {
	rm -rf .build/
	rm -rf *.xcodeproj
}

function build() {
	install_deps
	DEVELOPER_DIR="$DEVELOPER_DIR" \
	LDFLAGS="-L/usr/local/opt/openssl@1.1/lib" \
	CPPFLAGS="-I/usr/local/opt/openssl@1.1/include" \
	PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig" \
	swift build
}

function run_tests_parallel() {
	install_deps
	DEVELOPER_DIR="$DEVELOPER_DIR" \
	LDFLAGS="-L/usr/local/opt/openssl@1.1/lib" \
	CPPFLAGS="-I/usr/local/opt/openssl@1.1/include" \
	PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig" \
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
esac
