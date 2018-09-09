# Runtime Dump

Runtime dump of the existing tests is a very flexible mechanism for validating and filtering the tests that you'd like to run.
Avito Runner supports runtime dump as a separate command, it uses it while running tests in order to validate the set of passed tests against
the existing tests in the test bundle in order to prevent the execution of the non-existent tests and fail gracefully with an error.

## Supporting Runtime Dump

It is highly important to support this feature in your project, otherwise you won't be able to use the runner.

### Add a Principal Class key in Info.plist

```
<key>NSPrincipalClass</key>
<string>PrincipalClass</string> // this is an ObjC class name
```

### Add a Principal Class Implementation to your test target

```
@objc(PrincipalClass) // expose this Swift class in ObjC runtime using this name. This must match Info.plist value.
final class BaseTestObservationEntryPoint: NSObject {
    override public required init() {
        super.init()
        main()
    }

    func main() {
        // perform runtime dump if needed
    }
}
```

### Implement Runtime Dump Functionality

Currently the contract is simple: runner starts your test bundle with a specific env which points to the location where the runtime dump 
should be stored as a JSON file.

The environment variable is `AVITO_TEST_RUNNER_RUNTIME_TESTS_EXPORT_PATH`. An example input value could be any path like `/tmp/runtimedump.json`.

JSON contents should be an array of objects, each object consists of the following three fields:

- `className` - a runtime name of the `XCTestCase` subclass.
- `testMethods` - all test methods of the `className`, usually those are the functions that have prefix `test` and have `Void` return type
- `path` - the full path to the source file which contains this `className`. This could be an empty string, but the value must be present.

Example:

```
[
    {
        "className": "LoginTests", 
        "testMethods": [
            "testLogin",
            "testLoginFailsWithoutCredentials"
        ], 
        "path": "/src/LoginTests.swift"
    },
    ...
]
```

You may find the sample implementation of the runtime dump in [`TestApp/TestAppUITests/RuntimeDump`](../../TestApp/TestAppUITests/RuntimeDump)
