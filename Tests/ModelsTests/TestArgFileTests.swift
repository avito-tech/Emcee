import Foundation
import Models
import XCTest
import ModelsTestHelpers

final class TestArgFileTests: XCTestCase {
    func test___decoding_without_environment() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "additionalApp2"]
                }
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName("ClassName/testMethod"),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }
    
    func test___decoding_with_test_type() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "additionalApp2"]
                }
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName("ClassName/testMethod"),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }
    
    func test___decoding_with_environment() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "additionalApp2"]
                }
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName("ClassName/testMethod"),
                environment: ["value": "key"],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }

    func test___decoding_without_runner_and_app() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "additionalApp2"]
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName("ClassName/testMethod"),
                environment: ["value": "key"],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts(appBundle: nil, runner: nil)
            )
        )
    }

    func test___decoding_with_empty_additionalApplicationBundles() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": []
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName("ClassName/testMethod"),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts(additionalApplicationBundles: [])
            )
        )
    }

    private func buildArtifacts(
        appBundle: String? = "/appBundle",
        runner: String? = "/runner",
        additionalApplicationBundles: [String] = ["/additionalApp1", "additionalApp2"]
    ) -> BuildArtifacts {
        return BuildArtifactsFixtures.withLocalPaths(
            appBundle: appBundle,
            runner: runner,
            xcTestBundle: "/xcTestBundle",
            additionalApplicationBundles: additionalApplicationBundles
        )
    }
}

