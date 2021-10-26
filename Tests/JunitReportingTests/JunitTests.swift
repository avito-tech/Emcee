@testable import JunitReporting
import EmceeTypes
import Extensions
import Foundation
import XCTest

class JunitTests: XCTestCase {
    func testGeneratingBasicReport() throws {
        let testCase = JunitTestCase(
            className: "SomeTests",
            name: "name",
            timestamp: 10000,
            time: 10,
            hostname: "host.example.com",
            isFailure: true,
            failures: [JunitTestCaseFailure(reason: "a reason", fileLine: "file:12")]
        )
        let generator = JunitGenerator(testCases: [testCase], timeZone: TimeZone(secondsFromGMT: 3 * 3600)!)
        let xmlString = try generator.generateReport()
        
        let expectedXmlStringPath = #file.deletingLastPathComponent.appending(pathComponent: "basic.xml")
        let expectedXmlString = try String(contentsOfFile: expectedXmlStringPath)
        
        XCTAssertEqual(xmlString, expectedXmlString)
    }
    
    func testGeneratingReportWithControlCharacters() throws {
        var controlData = Data()
        controlData.append(12)
        controlData.append(07)
        let controlCharacters = String(data: controlData, encoding: .utf8)!
        let stringWithControlCharacters = "reason with -\(controlCharacters)- chars"
        
        let testCase = JunitTestCase(
            className: "SomeTests",
            name: "name",
            timestamp: 10000,
            time: 10,
            hostname: "host.example.com",
            isFailure: true,
            failures: [JunitTestCaseFailure(reason: stringWithControlCharacters, fileLine: "file:12")]
        )
        let generator = JunitGenerator(testCases: [testCase], timeZone: TimeZone(secondsFromGMT: 3 * 3600)!)
        let xmlString = try generator.generateReport()
        XCTAssertFalse(xmlString.contains(stringWithControlCharacters))
        XCTAssertTrue(xmlString.contains("reason with -- chars"))
    }
    
    func test___report_with_failed_test_but_without_test_failures() throws {
        let testCase = JunitTestCase(
            className: "SomeTests",
            name: "name",
            timestamp: 10000,
            time: 10,
            hostname: "host.example.com",
            isFailure: true,
            failures: []
        )
        let generator = JunitGenerator(testCases: [testCase], timeZone: TimeZone(secondsFromGMT: 3 * 3600)!)
        let xmlString = try generator.generateReport()
        
        let expectedXmlStringPath = #file.deletingLastPathComponent.appending(pathComponent: "failed_test_without_test_failures.xml")
        let expectedXmlString = try String(contentsOfFile: expectedXmlStringPath)
        
        XCTAssertEqual(xmlString, expectedXmlString)

    }
}
