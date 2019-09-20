import Foundation
import Models
import XCTest
import ModelsTestHelpers

final class TestArgFileTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(),
                environment: ["value": "key"],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }

    func test___decoding_full_json___fallback_xcTestBundle() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(runtimeDumpKind: .logicTest),
                environment: ["value": "key"],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }

    func test___decoding_without_environment_fallback_xcTestBundle() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"]
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(runtimeDumpKind: .logicTest),
                environment: [:],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }

    func test___decoding_without_environment() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"]
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(),
                environment: [:],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }
    
    func test___decoding_with_test_type() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(),
                environment: [:],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }
    
    func test___decoding_with_environment() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(),
                environment: ["value": "key"],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }
    
    func test___decoding_with_toolchain_configuration_current() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {
                    "developerDir": {"kind": "current"}
                },
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(),
                environment: [:],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }
    
    func test___decoding_with_toolchain_configuration_use_xcode() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {
                    "developerDir": {"kind": "useXcode", "CFBundleShortVersionString": "10.1"}
                },
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(),
                environment: [:],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                toolchainConfiguration: ToolchainConfiguration(
                    developerDir: .useXcode(CFBundleShortVersionString: "10.1")
                )
            )
        )
    }

    func test___decoding_without_runner_additionalApplicationBundles_and_app() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(appBundle: nil, runner: nil, additionalApplicationBundles: []),
                environment: ["value": "key"],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }

    func test___decoding_with_empty_additionalApplicationBundles() throws {
        let json = """
            {
                "testsToRun": [
                    {"predicateType": "singleTestName", "testName": "ClassName/testMethod"}
                ],
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": [],
                    "needHostAppToDumpTests": true
                },
                "toolchainConfiguration": {"developerDir": {"kind": "current"}},
                "scheduleStrategy": "unsplit"
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                buildArtifacts: buildArtifacts(additionalApplicationBundles: []),
                environment: [:],
                numberOfRetries: 42,
                scheduleStrategy: .unsplit,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
    }

    private func buildArtifacts(
        appBundle: String? = "/appBundle",
        runner: String? = "/runner",
        additionalApplicationBundles: [String] = ["/additionalApp1", "/additionalApp2"],
        runtimeDumpKind: RuntimeDumpKind = .appTest
    ) -> BuildArtifacts {
        return BuildArtifactsFixtures.withLocalPaths(
            appBundle: appBundle,
            runner: runner,
            xcTestBundle: "/xcTestBundle",
            additionalApplicationBundles: additionalApplicationBundles,
            runtimeDumpKind: runtimeDumpKind
        )
    }
}

