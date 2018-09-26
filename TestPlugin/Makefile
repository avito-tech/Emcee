generate:
	swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig
.PHONY: generate

open: generate
	open *.xcodeproj

build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --static-swift-stdlib
	rm -rf .build/debug/TestPlugin.emceeplugin/
	mkdir -p .build/debug/TestPlugin.emceeplugin/
	cp .build/debug/Plugin .build/debug/TestPlugin.emceeplugin/

run:
	swift run -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13" --static-swift-stdlib
