import Foundation
import Models
import XCTest

final class TestArgFileTests: XCTestCase {
    func test___decoding_without_environment() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"}
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
                testType: .uiTest
            )
        )
    }
    
    func test___decoding_with_test_type() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest"
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
                testType: .logicTest
            )
        )
    }
    
    func test___decoding_with_environment() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"}
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
                testType: .uiTest
            )
        )
    }
}

