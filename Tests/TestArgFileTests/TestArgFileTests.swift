import BuildArtifacts
import Foundation
import LoggingSetup
import QueueModels
import ResourceLocation
import Sentry
import SimulatorPoolModels
import SocketModels
import TestArgFile
import XCTest

final class TestArgFileTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = """
            {
                "entries": [],
                "jobGroupId": "jobGroupId",
                "jobGroupPriority": 100,
                "jobId": "jobId",
                "jobPriority": 500,
                "testDestinationConfigurations": [],
                "persistentMetricsJobId": "persistentMetricsJobId",
                "analyticsConfiguration": {
                    "graphiteConfiguration": {
                        "socketAddress": "graphite.host:123",
                        "metricPrefix": "graphite.prefix",
                    },
                    "statsdConfiguration": {
                        "socketAddress": "statsd.host:124",
                        "metricPrefix": "statsd.prefix",
                    },
                    "sentryConfiguration": {
                        "dsn": "http://example.com",
                    }
                }
            }
        """.data(using: .utf8)!
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertEqual(
            testArgFile,
            TestArgFile(
                analyticsConfiguration: AnalyticsConfiguration(
                    graphiteConfiguration: MetricConfiguration(
                        socketAddress: SocketAddress(host: "graphite.host", port: 123),
                        metricPrefix: "graphite.prefix"
                    ),
                    statsdConfiguration: MetricConfiguration(
                        socketAddress: SocketAddress(host: "statsd.host", port: 124),
                        metricPrefix: "statsd.prefix"
                    ),
                    sentryConfiguration: SentryConfiguration(dsn: URL(string: "http://example.com")!)
                ),
                entries: [],
                prioritizedJob: PrioritizedJob(
                    jobGroupId: "jobGroupId",
                    jobGroupPriority: 100,
                    jobId: "jobId",
                    jobPriority: 500,
                    persistentMetricsJobId: "persistentMetricsJobId"
                ),
                testDestinationConfigurations: []
            )
        )
    }
    
    func test___decoding_short_json() throws {
        let json = """
            {
                "entries": [],
                "jobId": "jobId",
            }
        """.data(using: .utf8)!
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertEqual(
            testArgFile,
            TestArgFile(
                analyticsConfiguration: TestArgFileDefaultValues.analyticsConfiguration,
                entries: [],
                prioritizedJob: PrioritizedJob(
                    jobGroupId: "jobId",
                    jobGroupPriority: TestArgFileDefaultValues.priority,
                    jobId: "jobId",
                    jobPriority: TestArgFileDefaultValues.priority,
                    persistentMetricsJobId: TestArgFileDefaultValues.persistentMetricsJobId
                ),
                testDestinationConfigurations: []
            )
        )
    }
    
    func test___complete_short_example() throws {
        let json = """
            {
                "jobId": "jobId",
                "entries": [
                    {
                        "testsToRun": ["all"],
                        "testDestination": {"deviceType": "iPhone X", "runtime": "11.3"},
                        "testType": "uiTest",
                        "buildArtifacts": {
                            "appBundle": "http://example.com/App.zip#MyApp/MyApp.app",
                            "runner": "http://example.com/App.zip#Tests/UITests-Runner.app",
                            "xcTestBundle": "http://example.com/App.zip#Tests/UITests-Runner.app/PlugIns/UITests.xctest"
                        }
                    }
                ]
            }
        """.data(using: .utf8)!
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertEqual(testArgFile.prioritizedJob.jobId, "jobId")
        XCTAssertEqual(testArgFile.entries.count, 1)
        XCTAssertEqual(testArgFile.entries[0].testsToRun, [.allDiscoveredTests])
        XCTAssertEqual(testArgFile.entries[0].testDestination, try TestDestination(deviceType: "iPhone X", runtime: "11.3"))
        XCTAssertEqual(testArgFile.entries[0].testType, .uiTest)
        XCTAssertEqual(
            testArgFile.entries[0].buildArtifacts,
            BuildArtifacts(
                appBundle: AppBundleLocation(try .from("http://example.com/App.zip#MyApp/MyApp.app")),
                runner: RunnerAppLocation(try .from("http://example.com/App.zip#Tests/UITests-Runner.app")),
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(try .from("http://example.com/App.zip#Tests/UITests-Runner.app/PlugIns/UITests.xctest")),
                    testDiscoveryMode: .parseFunctionSymbols
                ),
                additionalApplicationBundles: []
            )
        )
    }
}

