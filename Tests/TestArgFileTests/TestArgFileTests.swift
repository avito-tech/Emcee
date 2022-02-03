import BuildArtifacts
import Foundation
import MetricsExtensions
import QueueModels
import ResourceLocation
import SimulatorPoolModels
import SocketModels
import TestArgFile
import TestDestination
import TestHelpers
import XCTest

final class TestArgFileTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = Data(
            """
            {
                "entries": [],
                "jobGroupId": "jobGroupId",
                "jobGroupPriority": 100,
                "jobId": "jobId",
                "jobPriority": 500,
                "testDestinationConfigurations": [],
                "analyticsConfiguration": {
                    "graphiteConfiguration": {
                        "socketAddress": "graphite.host:123",
                        "metricPrefix": "graphite.prefix",
                    },
                    "statsdConfiguration": {
                        "socketAddress": "statsd.host:124",
                        "metricPrefix": "statsd.prefix",
                    },
                    "kibanaConfiguration": {
                        "endpoints": [
                            "http://kibana.example.com:9200"
                        ],
                        "indexPattern": "index-pattern"
                    },
                    "persistentMetricsJobId": "persistentMetricsJobId",
                    "metadata": {
                        "some": "value"
                    }
                }
            }
            """.utf8
        )
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertEqual(
            testArgFile,
            TestArgFile(
                entries: [],
                prioritizedJob: PrioritizedJob(
                    analyticsConfiguration: AnalyticsConfiguration(
                        graphiteConfiguration: MetricConfiguration(
                            socketAddress: SocketAddress(host: "graphite.host", port: 123),
                            metricPrefix: "graphite.prefix"
                        ),
                        statsdConfiguration: MetricConfiguration(
                            socketAddress: SocketAddress(host: "statsd.host", port: 124),
                            metricPrefix: "statsd.prefix"
                        ),
                        kibanaConfiguration: KibanaConfiguration(
                            endpoints: [
                                URL(string: "http://kibana.example.com:9200")!
                            ],
                            indexPattern: "index-pattern"
                        ),
                        persistentMetricsJobId: "persistentMetricsJobId",
                        metadata: ["some": "value"]
                    ),
                    jobGroupId: "jobGroupId",
                    jobGroupPriority: 100,
                    jobId: "jobId",
                    jobPriority: 500
                ),
                testDestinationConfigurations: []
            )
        )
    }
    
    func test___decoding_short_json() throws {
        let json = Data(
            """
            {
                "entries": [],
                "jobId": "jobId",
            }
            """.utf8
        )
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertEqual(
            testArgFile,
            TestArgFile(
                entries: [],
                prioritizedJob: PrioritizedJob(
                    analyticsConfiguration: TestArgFileDefaultValues.analyticsConfiguration,
                    jobGroupId: "jobId",
                    jobGroupPriority: TestArgFileDefaultValues.priority,
                    jobId: "jobId",
                    jobPriority: TestArgFileDefaultValues.priority
                ),
                testDestinationConfigurations: []
            )
        )
    }
    
    func test___complete_short_example() throws {
        let json = Data(
            """
            {
                "entries": [
                    {
                        "testsToRun": [
                            "all"
                        ],
                        "testDestination": {
                            "deviceType": "iPhone X",
                            "runtime": "11.3"
                        },
                        "testType": "uiTest",
                        "buildArtifacts": {
                            "appBundle": {
                                "url": "http://example.com/App.zip#MyApp/MyApp.app"
                            },
                            "runner": {
                                "url": "http://example.com/App.zip#Tests/UITests-Runner.app"
                            },
                            "xcTestBundle": {
                                "url": "http://example.com/App.zip#Tests/UITests-Runner.app/PlugIns/UITests.xctest"
                            }
                        }
                    }
                ]
            }
            """.utf8
        )
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertTrue(testArgFile.prioritizedJob.jobId.value.hasPrefix("automaticJobId_")) 
        XCTAssertEqual(testArgFile.entries.count, 1)
        XCTAssertEqual(testArgFile.entries[0].testsToRun, [.allDiscoveredTests])
        XCTAssertEqual(testArgFile.entries[0].testDestination, TestDestination.iOSSimulator(deviceType: "iPhone X", version: "11.3"))
        XCTAssertEqual(
            testArgFile.entries[0].buildArtifacts,
            IosBuildArtifacts.iosUiTests(
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(try .from("http://example.com/App.zip#Tests/UITests-Runner.app/PlugIns/UITests.xctest")),
                    testDiscoveryMode: .parseFunctionSymbols
                ),
                appBundle: AppBundleLocation(try .from("http://example.com/App.zip#MyApp/MyApp.app")),
                runner: RunnerAppLocation(try .from("http://example.com/App.zip#Tests/UITests-Runner.app")),
                additionalApplicationBundles: []
            )
        )
    }
}

