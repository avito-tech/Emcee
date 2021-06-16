import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import PluginSupport
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestHelpers
import XCTest

final class TestArgFileEntryTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = Data(
            """
            {
                "testsToRun": [
                    {
                        "predicateType": "singleTestName",
                        "testName": "ClassName/testMethod"
                    }
                ],
                "environment": {
                    "value": "key"
                },
                "numberOfRetries": 42,
                "testDestination": {
                    "deviceType": "iPhone SE",
                    "runtime": "11.3"
                },
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": {
                        "url": "/appBundle"
                    },
                    "runner": {
                        "url": "/runner"
                    },
                    "xcTestBundle": {
                        "location": {
                            "url": "/xcTestBundle"
                        },
                        "testDiscoveryMode": "runtimeAppTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1","/additionalApp2"]
                },
                "testRunnerTool": {
                    "toolType": "xcodebuild"
                },
                "simulatorControlTool": {
                    "location": "insideUserLibrary",
                    "tool": {
                        "toolType": "simctl"
                    }
                },
                "developerDir": {
                    "kind": "current"
                },
                "pluginLocations": [
            {"url":"http://example.com/plugin.zip#sample.emceeplugin"}],
                "scheduleStrategy": "unsplit",
                "simulatorOperationTimeouts": {
                    "create": 50,
                    "boot": 51,
                    "delete": 52,
                    "shutdown": 53,
                    "automaticSimulatorShutdown": 54,
                    "automaticSimulatorDelete": 55
                },
                "simulatorSettings": {
                    "simulatorLocalizationSettings": {
                        "localeIdentifier": "ru_US",
                        "keyboards": [
                            "ru_RU@sw=Russian;hw=Automatic",
                            "en_US@sw=QWERTY;hw=Automatic"
                        ],
                        "passcodeKeyboards": [
                            "ru_RU@sw=Russian;hw=Automatic",
                            "en_US@sw=QWERTY;hw=Automatic"
                        ],
                        "languages": [
                            "ru-US",
                            "en",
                            "ru-RU"
                        ],
                        "addingEmojiKeybordHandled": true,
                        "enableKeyboardExpansion": true,
                        "didShowInternationalInfoAlert": true,
                        "didShowContinuousPathIntroduction": true
                    },
                    "watchdogSettings": {
                        "bundleIds": [
                            "sample.app"
                        ],
                        "timeout": 42
                    },
                },
                "testTimeoutConfiguration": {
                    "singleTestMaximumDuration": 42,
                    "testRunnerMaximumSilenceDuration": 24
                },
                "workerCapabilityRequirements": []
            }
            """.utf8
        )
        
        let entry = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFileEntry.self, from: json)
        }

        XCTAssertEqual(
            entry,
            TestArgFileEntry(
                buildArtifacts: buildArtifacts(),
                developerDir: .current,
                environment: ["value": "key"],
                numberOfRetries: 42,
                pluginLocations: [
                    PluginLocation(.remoteUrl(URL(string: "http://example.com/plugin.zip#sample.emceeplugin")!, [:]))
                ],
                scheduleStrategy: .unsplit,
                simulatorControlTool: SimulatorControlTool(
                    location: .insideUserLibrary,
                    tool: .simctl
                ),
                simulatorOperationTimeouts: SimulatorOperationTimeouts(
                    create: 50,
                    boot: 51,
                    delete: 52,
                    shutdown: 53,
                    automaticSimulatorShutdown: 54,
                    automaticSimulatorDelete: 55
                ),
                simulatorSettings: SimulatorSettings(
                    simulatorLocalizationSettings: SimulatorLocalizationSettingsFixture().simulatorLocalizationSettings(),
                    watchdogSettings: WatchdogSettings(bundleIds: ["sample.app"], timeout: 42)
                ),
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testRunnerTool: .xcodebuild,
                testTimeoutConfiguration: TestTimeoutConfiguration(
                    singleTestMaximumDuration: 42,
                    testRunnerMaximumSilenceDuration: 24
                ),
                testType: .logicTest,
                testsToRun: [.testName(TestName(className: "ClassName", methodName: "testMethod"))],
                workerCapabilityRequirements: []
            )
        )
    }
    
    func test___decoding_short_json() throws {
        let json = Data(
            """
            {
                "testsToRun": [
                    "all",
                    "ClassName/testMethod",
                    {
                        "predicateType": "singleTestName",
                        "testName": "ClassName/testMethod"
                    }
                ],
                "testDestination": {
                    "deviceType": "iPhone SE",
                    "runtime": "11.3"
                },
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": {
                        "url": "/appBundle"
                    },
                    "runner": {
                        "url": "/runner"
                    },
                    "xcTestBundle": {
                        "location": {"url":"/xcTestBundle"},
                        "testDiscoveryMode": "runtimeAppTest"
                    },
                    "additionalApplicationBundles": [
                        {
                            "url": "/additionalApp1"
                        },
                        {
                            "url": "/additionalApp2"
                        }
                    ]
                }
            }
            """.utf8
        )
        
        let entry = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFileEntry.self, from: json)
        }

        XCTAssertEqual(
            entry,
            TestArgFileEntry(
                buildArtifacts: buildArtifacts(),
                developerDir: TestArgFileDefaultValues.developerDir,
                environment: TestArgFileDefaultValues.environment,
                numberOfRetries: TestArgFileDefaultValues.numberOfRetries,
                pluginLocations: TestArgFileDefaultValues.pluginLocations,
                scheduleStrategy: TestArgFileDefaultValues.scheduleStrategy,
                simulatorControlTool: TestArgFileDefaultValues.simulatorControlTool,
                simulatorOperationTimeouts: TestArgFileDefaultValues.simulatorOperationTimeouts,
                simulatorSettings: TestArgFileDefaultValues.simulatorSettings,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testRunnerTool: TestArgFileDefaultValues.testRunnerTool,
                testTimeoutConfiguration: TestArgFileDefaultValues.testTimeoutConfiguration,
                testType: .logicTest,
                testsToRun: [
                    .allDiscoveredTests,
                    .testName(TestName(className: "ClassName", methodName: "testMethod")),
                    .testName(TestName(className: "ClassName", methodName: "testMethod")),
                ],
                workerCapabilityRequirements: TestArgFileDefaultValues.workerCapabilityRequirements
            )
        )
    }
    
    private func buildArtifacts(
        appBundle: String? = "/appBundle",
        runner: String? = "/runner",
        additionalApplicationBundles: [String] = ["/additionalApp1", "/additionalApp2"],
        testDiscoveryMode: XcTestBundleTestDiscoveryMode = .runtimeAppTest
    ) -> BuildArtifacts {
        return BuildArtifactsFixtures.withLocalPaths(
            appBundle: appBundle,
            runner: runner,
            xcTestBundle: "/xcTestBundle",
            additionalApplicationBundles: additionalApplicationBundles,
            testDiscoveryMode: testDiscoveryMode
        )
    }
}

