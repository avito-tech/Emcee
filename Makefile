install_deps:
	brew ls --versions pkg-config > /dev/null || brew install pkg-config
	brew ls --versions libssh2 > /dev/null || brew install libssh2

generate: install_deps
	swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig --enable-code-coverage
.PHONY: generate

open: generate
	open *.xcodeproj
.PHONY: open

clean:
	rm -rf .build/
	rm -rf TestPlugin/.build/
.PHONY: clean

build: install_deps
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --static-swift-stdlib

run: install_deps
	swift run -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --static-swift-stdlib

test: install_deps
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" 

test-parallel: install_deps
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --parallel

integration-test: install_deps
	auxiliary/run_smoke_tests.sh

rerun-integration-test: install_deps
	PYCACHE_ENABLED=true auxiliary/run_smoke_tests.sh
