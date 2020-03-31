@testable import TestDiscovery
import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestToRunIntoTestEntryTransformerTests: XCTestCase {
    private let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    private let transformer = TestToRunIntoTestEntryTransformer()

    func test__transforming_concrete_test_names() throws {
        let queryResult = TestDiscoveryResult(
            discoveredTests: DiscoveredTests(
                tests: [
                    DiscoveredTestEntryFixtures.entry(className: "class", testMethods: ["test1", "test2", "test3"])
                ]
            ),
            unavailableTestsToRun: []
        )
        
        let transformationResult = try transformer.transform(
            buildArtifacts: fakeBuildArtifacts,
            testDiscoveryResult: queryResult
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
        
        let testDiscoveryResult = TestDiscoveryResult(
            discoveredTests: DiscoveredTests(
                tests: [
                    DiscoveredTestEntryFixtures.entry()
                ]
            ),
            unavailableTestsToRun: [
                missingTest
            ]
        )
        
        XCTAssertThrowsError(_ = try transformer.transform(buildArtifacts: fakeBuildArtifacts, testDiscoveryResult: testDiscoveryResult))
    }
}
