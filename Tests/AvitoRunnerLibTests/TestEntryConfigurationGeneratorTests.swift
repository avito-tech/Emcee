import AvitoRunnerLib
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestEntryConfigurationGeneratorTests: XCTestCase {
    let argFileTestToRun1 = TestToRun.testName("classFromArgs/test1")
    let argFileTestToRun2 = TestToRun.testName("classFromArgs/test2")
    
    let buildArtifacts = BuildArtifactsFixtures.withLocalPaths(
        appBundle: "1",
        runner: "1",
        xcTestBundle: "1",
        additionalApplicationBundles: ["1", "2"]
    )
    let argFileDestination1 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.1")
    let argFileDestination2 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.2")

    lazy var validatedEnteries: [TestToRun : [TestEntry]] = {
        return [
            argFileTestToRun1: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1")],
            argFileTestToRun2: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2")]
        ]
    }()
    
    func test() {
        let generator = TestEntryConfigurationGenerator(
            validatedEnteries: validatedEnteries,
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
            buildArtifacts: buildArtifacts
        )
        
        let configurations = generator.createTestEntryConfigurations()
        
        let expectedConfigurations = [
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination1)
                .testEntryConfigurations(),
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2"))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 20))
                .with(testDestination: argFileDestination2)
                .testEntryConfigurations()
            ].flatMap { $0 }
        
        XCTAssertEqual(Set(configurations), Set(expectedConfigurations))
    }
}
