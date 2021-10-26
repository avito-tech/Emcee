#  ResultStreamModels

This module represents a set of models that `xcodebuild -resultStreamPath <JSON file>` consists of. 
This file is a JSON stream, updated on the fly while the `xcodebuild` is running.

## How to add models?

1. Run `xcodebuild test -resultStreamPath <path to file that will be created>`
2. Inspect the file after `xcodebuild` terminates. Describe all objects as Swift models.
3. You can also inspect `XCResultKit` framework in Xcode, e.g. using Hopper  
