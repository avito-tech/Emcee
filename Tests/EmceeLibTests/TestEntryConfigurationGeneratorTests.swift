import EmceeLib
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestEntryConfigurationGeneratorTests: XCTestCase {
    let argFileTestToRun1 = TestToRun.testName(TestName(className: "classFromArgs", methodName: "test1"))
    let argFileTestToRun2 = TestToRun.testName(TestName(className: "classFromArgs", methodName: "test2"))
    
    let buildArtifacts = BuildArtifactsFixtures.withLocalPaths(
        appBundle: "1",
        runner: "1",
        xcTestBundle: "1",
        additionalApplicationBundles: ["1", "2"]
    )
    let argFileDestination1 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.1")
    let argFileDestination2 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.2")

    lazy var validatedEnteries: [ValidatedTestEntry] = {
        return [
            ValidatedTestEntry(
                testToRun: argFileTestToRun1,
                testEntries: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1")],
                buildArtifacts: buildArtifacts
            ),
            ValidatedTestEntry(
                testToRun: argFileTestToRun2,
                testEntries: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2")],
                buildArtifacts: buildArtifacts
            )
        ]
    }()
    
    func test() {
        let generator = TestEntryConfigurationGenerator(
            validatedEnteries: validatedEnteries,
            testArgEntries: [
                TestArgFile.Entry(
                    testsToRun: [argFileTestToRun1],
                    buildArtifacts: buildArtifacts,
                    environment: [:],
                    numberOfRetries: 10,
                    testDestination: argFileDestination1,
                    testType: .uiTest,
                    toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
                ),
                TestArgFile.Entry(
                    testsToRun: [argFileTestToRun2],
                    buildArtifacts: buildArtifacts,
                    environment: [:],
                    numberOfRetries: 20,
                    testDestination: argFileDestination2,
                    testType: .appTest,
                    toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
                )
            ]
        )
        
        let configurations = generator.createTestEntryConfigurations()
        
        let expectedConfigurations = [
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination1)
                .with(testType: .uiTest)
                .testEntryConfigurations(),
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2"))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 20))
                .with(testDestination: argFileDestination2)
                .with(testType: .appTest)
                .testEntryConfigurations()
            ].flatMap { $0 }
        
        XCTAssertEqual(Set(configurations), Set(expectedConfigurations))
    }
    
    func test_repeated_items() {
        let generator = TestEntryConfigurationGenerator(
            validatedEnteries: validatedEnteries,
            testArgEntries: [
                TestArgFile.Entry(
                    testsToRun: [argFileTestToRun1, argFileTestToRun1],
                    buildArtifacts: buildArtifacts,
                    environment: [:],
                    numberOfRetries: 10,
                    testDestination: argFileDestination1,
                    testType: .uiTest,
                    toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
                )
            ]
        )
        
        let expectedTestEntryConfigurations =
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
                .with(buildArtifacts: buildArtifacts)
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination1)
                .with(testType: .uiTest)
                .testEntryConfigurations()
        
        XCTAssertEqual(
            generator.createTestEntryConfigurations(),
            expectedTestEntryConfigurations + expectedTestEntryConfigurations
        )
    }
}
