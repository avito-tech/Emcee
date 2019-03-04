import AvitoRunnerLib
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestEntryConfigurationGeneratorTests: XCTestCase {
    let testNameToRun = TestToRun.testName("class/testName")
    let testIdToRun = TestToRun.caseId(42)
    let argFileTestToRun1 = TestToRun.testName("classFromArgs/test1")
    let argFileTestToRun2 = TestToRun.testName("classFromArgs/test2")
    
    let buildArtifacts = BuildArtifactsFixtures.withLocalPaths(
        appBundle: "1",
        runner: "1",
        xcTestBundle: "1",
        additionalApplicationBundles: ["1", "2"]
    )
    let testExecutionBehavior = TestExecutionBehavior(environment: [:], numberOfRetries: 1)
    let testDestination = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.0")
    let argFileDestination1 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.1")
    let argFileDestination2 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.2")

    lazy var validatedEnteries: [TestToRun : [TestEntry]] = {
        return [
            testNameToRun: [TestEntry(className: "class", methodName: "testName", caseId: nil)],
            testIdToRun: [
                TestEntry(className: "class42", methodName: "testName42_1", caseId: 42),
                TestEntry(className: "class42", methodName: "testName42_2", caseId: 42)
            ],
            argFileTestToRun1: [TestEntry(className: "classFromArgs", methodName: "test1", caseId: nil)],
            argFileTestToRun2: [TestEntry(className: "classFromArgs", methodName: "test2", caseId: nil)]
        ]
    }()
    
    func test() {
        let generator = TestEntryConfigurationGenerator(
            validatedEnteries: validatedEnteries,
            explicitTestsToRun: [testIdToRun, testNameToRun],
            testArgEntries: [
                TestArgFile.Entry(
                    testToRun: argFileTestToRun1,
                    environment: [:],
                    numberOfRetries: 10,
                    testDestination: argFileDestination1
                ),
                TestArgFile.Entry(
                    testToRun: argFileTestToRun2,
                    environment: [:],
                    numberOfRetries: 20,
                    testDestination: argFileDestination2
                ),
            ],
            commonTestExecutionBehavior: testExecutionBehavior,
            commonTestDestinations: [testDestination],
            commonBuildArtifacts: buildArtifacts
        )
        
        let configurations = generator.createTestEntryConfigurations()
        
        let expectedConfigurations = [
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntry(className: "class42", methodName: "testName42_1", caseId: 42))
                .add(testEntry: TestEntry(className: "class42", methodName: "testName42_2", caseId: 42))
                .add(testEntry: TestEntry(className: "class", methodName: "testName", caseId: nil))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: testExecutionBehavior)
                .with(testDestination: testDestination)
                .testEntryConfigurations(),
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntry(className: "classFromArgs", methodName: "test1", caseId: nil))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination1)
                .testEntryConfigurations(),
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntry(className: "classFromArgs", methodName: "test2", caseId: nil))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 20))
                .with(testDestination: argFileDestination2)
                .testEntryConfigurations()
            ].flatMap { $0 }
        
        XCTAssertEqual(Set(configurations), Set(expectedConfigurations))
    }
}
