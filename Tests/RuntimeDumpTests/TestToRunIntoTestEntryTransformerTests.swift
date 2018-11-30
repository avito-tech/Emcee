import Foundation
import Models
@testable import RuntimeDump
import XCTest

final class TestToRunIntoTestEntryTransformerTests: XCTestCase {
    func test__transforming_concrete_test_names() throws {
        let testsToRun = [
            TestToRun.testName("class/test1"),
            TestToRun.testName("class/test2"),
            TestToRun.testName("class/test3")
        ]
        
        let transformer = TestToRunIntoTestEntryTransformer(testsToRun: testsToRun)
        let queryResult = RuntimeQueryResult(
            unavailableTestsToRun: [],
            availableRuntimeTests: [
                RuntimeTestEntry(className: "class", path: "", testMethods: ["test1", "test2", "test3"], caseId: nil, tags: [])
            ])
        
        let transformationResult = try transformer.transform(runtimeQueryResult: queryResult)
        XCTAssertEqual(
            transformationResult,
            [
                TestToRun.testName("class/test1"): [TestEntry(className: "class", methodName: "test1", caseId: nil)],
                TestToRun.testName("class/test2"): [TestEntry(className: "class", methodName: "test2", caseId: nil)],
                TestToRun.testName("class/test3"): [TestEntry(className: "class", methodName: "test3", caseId: nil)]
            ]
        )
    }
    
    func test__with_missing_tests() throws {
        let missingTest = TestToRun.caseId(404)
        let testToRunWithCaseId = TestToRun.caseId(42)
        
        let transformer = TestToRunIntoTestEntryTransformer(testsToRun: [testToRunWithCaseId])
        let queryResult = RuntimeQueryResult(
            unavailableTestsToRun: [
                missingTest
            ],
            availableRuntimeTests: [
                RuntimeTestEntry(className: "class", path: "", testMethods: ["test"], caseId: 42, tags: [])
            ])
        
        XCTAssertThrowsError(_ = try transformer.transform(runtimeQueryResult: queryResult))
    }
}

