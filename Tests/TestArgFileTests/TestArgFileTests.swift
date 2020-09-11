import BuildArtifacts
import Foundation
import ResourceLocation
import SimulatorPoolModels
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
                "persistentMetricsJobId": "persistentMetricsJobId"
            }
        """.data(using: .utf8)!
        
        let testArgFile = assertDoesNotThrow {
            try JSONDecoder().decode(TestArgFile.self, from: json)
        }

        XCTAssertEqual(
            testArgFile,
            TestArgFile(
                entries: [],
                jobGroupId: "jobGroupId",
                jobGroupPriority: 100,
                jobId: "jobId",
                jobPriority: 500,
                testDestinationConfigurations: [],
                persistentMetricsJobId: "persistentMetricsJobId"
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
                entries: [],
                jobGroupId: "jobId",
                jobGroupPriority: TestArgFileDefaultValues.priority,
                jobId: "jobId",
                jobPriority: TestArgFileDefaultValues.priority,
                testDestinationConfigurations: [],
                persistentMetricsJobId: TestArgFileDefaultValues.persistentMetricsJobId
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

        XCTAssertEqual(testArgFile.jobId, "jobId")
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

