#!/bin/bash

cd "$(dirname "$0")"

set -xueo pipefail

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
}

function open_xcodeproj() {
	generate_xcodeproj
	open *.xcodeproj
}

function generate_xcodeproj() {
	install_deps
	swift package generate-xcodeproj --enable-code-coverage
}

function clean() {
	rm -rf .build/
	rm -rf *.xcodeproj
}

function build() {
	install_deps
	swift build
}

function run_tests_parallel() {
	install_deps
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
