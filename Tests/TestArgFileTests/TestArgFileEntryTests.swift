import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import PluginSupport
import RunnerModels
import RunnerTestHelpers
import ScheduleStrategy
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
                "developerDir": {
                    "kind": "current"
                },
                "pluginLocations": [
                    {
                        "url":"http://example.com/plugin.zip#sample.emceeplugin"
                    }
                ],
                "scheduleStrategy": {"testSplitterType":{"type":"unsplit"}},
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
                        "didShowContinuousPathIntroduction": true,
                        "didShowGestureKeyboardIntroduction": true
                    },
                    "simulatorKeychainSettings": {
                        "rootCerts": [
                            "http://example.com/cert.zip#cert.pem",
                            "http://example.com/cert2.zip#cert2.pem"
                        ]
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
                scheduleStrategy: ScheduleStrategy(testSplitterType: .unsplit),
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
                    simulatorKeychainSettings: SimulatorKeychainSettings(
                        rootCerts: [
                            SimulatorCertificateLocation(.remoteUrl(URL(string: "http://example.com/cert.zip#cert.pem")!, nil)),
                            SimulatorCertificateLocation(.remoteUrl(URL(string: "http://example.com/cert2.zip#cert2.pem")!, nil))
                        ]
                    ),
                    watchdogSettings: WatchdogSettings(bundleIds: ["sample.app"], timeout: 42)
                ),
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testTimeoutConfiguration: TestTimeoutConfiguration(
                    singleTestMaximumDuration: 42,
                    testRunnerMaximumSilenceDuration: 24
                ),
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
                simulatorOperationTimeouts: TestArgFileDefaultValues.simulatorOperationTimeouts,
                simulatorSettings: TestArgFileDefaultValues.simulatorSettings,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testTimeoutConfiguration: TestArgFileDefaultValues.testTimeoutConfiguration,
                testsToRun: [
                    .allDiscoveredTests,
                    .testName(TestName(className: "ClassName", methodName: "testMethod")),
                    .testName(TestName(className: "ClassName", methodName: "testMethod")),
                ],
                workerCapabilityRequirements: TestArgFileDefaultValues.workerCapabilityRequirements
            )
        )
    }
    
    private func buildArtifacts() -> BuildArtifacts {
        .iosUiTests(
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath("/xcTestBundle")),
                testDiscoveryMode: .runtimeAppTest
            ),
            appBundle: AppBundleLocation(.localFilePath("/appBundle")),
            runner: RunnerAppLocation(.localFilePath("/runner")),
            additionalApplicationBundles: [
                AdditionalAppBundleLocation(.localFilePath("/additionalApp1")),
                AdditionalAppBundleLocation(.localFilePath("/additionalApp2")),
            ]
        )
    }
}

