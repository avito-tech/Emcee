generate:
	swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig
.PHONY: generate

open: generate
	open *.xcodeproj

build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --static-swift-stdlib

run:
	swift run -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --static-swift-stdlib

test:
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13"

integration-test: build
	cd TestPlugin && make build
	auxiliary/run_smoke_tests.sh
