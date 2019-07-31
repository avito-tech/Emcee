import Foundation
import Models
import ModelsTestHelpers
@testable import RuntimeDump
import XCTest

final class TestToRunIntoTestEntryTransformerTests: XCTestCase {
    private let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    private let transformer = TestToRunIntoTestEntryTransformer()

    func test__transforming_concrete_test_names() throws {
        let queryResult = RuntimeQueryResult(
            unavailableTestsToRun: [],
            availableRuntimeTests: [
                RuntimeTestEntry(className: "class", path: "", testMethods: ["test1", "test2", "test3"], caseId: nil, tags: [])
            ])
        
        let transformationResult = try transformer.transform(
            runtimeQueryResult: queryResult,
            buildArtifacts: fakeBuildArtifacts
        )
        
        let expectedTestNames = [
            TestName(className: "class", methodName: "test1"),
            TestName(className: "class", methodName: "test2"),
            TestName(className: "class", methodName: "test3")
        ]
        let expectedTransformationResult = expectedTestNames.flatMap { testName -> [ValidatedTestEntry] in
            return [
                ValidatedTestEntry(
                    testName: testName,
                    testEntries: [TestEntry(testName: testName, tags: [], caseId: nil)],
                    buildArtifacts: fakeBuildArtifacts
                )
            ]
        }
        XCTAssertEqual(
            transformationResult,
            expectedTransformationResult
        )
    }
    
    func test__with_missing_tests() throws {
        let missingTest = TestToRun.testName(TestName(className: "Class", methodName: "test404"))
        
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
