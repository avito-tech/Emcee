import Extensions
import Foundation
@testable import JunitReporting
import XCTest

class JunitTests: XCTestCase {
    func testGeneratingBasicReport() throws {
        let testCase = JunitTestCase(
            className: "SomeTests",
            name: "name",
            time: 10,
            isFailure: true,
            failures: [JunitTestCaseFailure(reason: "a reason", fileLine: "file:12")],
            boundaries: JunitTestCaseBoundaries(startTime: 1, finishTime: 11))
        let generator = JunitGenerator(testCases: [testCase])
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
            time: 10,
            isFailure: true,
            failures: [JunitTestCaseFailure(reason: stringWithControlCharacters, fileLine: "file:12")],
            boundaries: JunitTestCaseBoundaries(startTime: 1, finishTime: 11))
        let generator = JunitGenerator(testCases: [testCase])
        let xmlString = try generator.generateReport()
        XCTAssertFalse(xmlString.contains(stringWithControlCharacters))
        XCTAssertTrue(xmlString.contains("reason with -- chars"))
    }
}
