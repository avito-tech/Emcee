import EmceeLib
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestEntryConfigurationGeneratorTests: XCTestCase {
    let argFileTestToRun1 = TestName(className: "classFromArgs", methodName: "test1")
    let argFileTestToRun2 = TestName(className: "classFromArgs", methodName: "test2")
    
    let buildArtifacts = BuildArtifactsFixtures.withLocalPaths(
        appBundle: "1",
        runner: "1",
        xcTestBundle: "1",
        additionalApplicationBundles: ["1", "2"]
    )
    let argFileDestination1 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.1")
    let argFileDestination2 = try! TestDestination(deviceType: UUID().uuidString, runtime: "10.2")

    lazy var validatedEntries: [ValidatedTestEntry] = {
        return [
            ValidatedTestEntry(
                testName: argFileTestToRun1,
                testEntries: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1")],
                buildArtifacts: buildArtifacts
            ),
            ValidatedTestEntry(
                testName: argFileTestToRun2,
                testEntries: [TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test2")],
                buildArtifacts: buildArtifacts
            )
        ]
    }()
    
    func test() {
        let generator = TestEntryConfigurationGenerator(
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFile.Entry(
                testsToRun: [.testName(argFileTestToRun1)],
                buildArtifacts: buildArtifacts,
                environment: [:],
                numberOfRetries: 10,
                scheduleStrategy: .unsplit,
                testDestination: argFileDestination1,
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
        
        let configurations = generator.createTestEntryConfigurations()
        
        let expectedConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry(className: "classFromArgs", methodName: "test1"))
            .with(buildArtifacts: buildArtifacts)
            .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
            .with(testDestination: argFileDestination1)
            .with(testType: .uiTest)
            .testEntryConfigurations()
        
        XCTAssertEqual(Set(configurations), Set(expectedConfigurations))
    }
    
    func test_repeated_items() {
        let generator = TestEntryConfigurationGenerator(
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFile.Entry(
                testsToRun: [.testName(argFileTestToRun1), .testName(argFileTestToRun1)],
                buildArtifacts: buildArtifacts,
                environment: [:],
                numberOfRetries: 10,
                scheduleStrategy: .unsplit,
                testDestination: argFileDestination1,
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
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
    
    func test__all_available_tests() {
        let generator = TestEntryConfigurationGenerator(
            validatedEntries: validatedEntries,
            testArgFileEntry: TestArgFile.Entry(
                testsToRun: [.allProvidedByRuntimeDump],
                buildArtifacts: buildArtifacts,
                environment: [:],
                numberOfRetries: 10,
                scheduleStrategy: .unsplit,
                testDestination: argFileDestination1,
                testType: .uiTest,
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        )
        
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
                .with(testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 10))
                .with(testDestination: argFileDestination1)
                .with(testType: .uiTest)
                .testEntryConfigurations()
            ].flatMap { $0 }
        
        XCTAssertEqual(
            Set(generator.createTestEntryConfigurations()),
            Set(expectedConfigurations)
        )
    }
}
