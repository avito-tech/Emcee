import Foundation
import Models
import ModelsTestHelpers
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
                TestToRun.testName("class/test1"): [TestEntryFixtures.testEntry(className: "class", methodName: "test1")],
                TestToRun.testName("class/test2"): [TestEntryFixtures.testEntry(className: "class", methodName: "test2")],
                TestToRun.testName("class/test3"): [TestEntryFixtures.testEntry(className: "class", methodName: "test3")]
            ]
        )
    }
    
    func test__with_missing_tests() throws {
        let missingTest = TestToRun.testName("Class/test404")
        let testToRunWithCaseId = TestToRun.testName("Class/testExisting")
        
        let transformer = TestToRunIntoTestEntryTransformer(testsToRun: [testToRunWithCaseId])
        let queryResult = RuntimeQueryResult(
            unavailableTestsToRun: [
                missingTest
            ],
            availableRuntimeTests: [
                RuntimeTestEntry(className: "class", path: "", testMethods: ["test"], caseId: nil, tags: [])
            ])
        
        XCTAssertThrowsError(_ = try transformer.transform(runtimeQueryResult: queryResult))
    }
}

