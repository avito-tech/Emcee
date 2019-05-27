import Foundation
import Models
import ModelsTestHelpers
@testable import RuntimeDump
import XCTest

final class TestToRunIntoTestEntryTransformerTests: XCTestCase {
    private let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()

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
        
        let transformationResult = try transformer.transform(
            runtimeQueryResult: queryResult,
            buildArtifacts: fakeBuildArtifacts
        )

        XCTAssertEqual(transformationResult.count, 3)
        XCTAssertEqual(
            transformationResult[0],
            ValidatedTestEntry(
                testToRun: TestToRun.testName("class/test1"),
                testEntries: [TestEntryFixtures.testEntry(className: "class", methodName: "test1")],
                buildArtifacts: fakeBuildArtifacts
            )
        )
        XCTAssertEqual(
            transformationResult[1],
            ValidatedTestEntry(
                testToRun: TestToRun.testName("class/test2"),
                testEntries: [TestEntryFixtures.testEntry(className: "class", methodName: "test2")],
                buildArtifacts: fakeBuildArtifacts
            )
        )
        XCTAssertEqual(
            transformationResult[2],
            ValidatedTestEntry(
                testToRun: TestToRun.testName("class/test3"),
                testEntries: [TestEntryFixtures.testEntry(className: "class", methodName: "test3")],
                buildArtifacts: fakeBuildArtifacts
            )
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
        
        XCTAssertThrowsError(_ = try transformer.transform(runtimeQueryResult: queryResult, buildArtifacts: fakeBuildArtifacts))
    }
}

