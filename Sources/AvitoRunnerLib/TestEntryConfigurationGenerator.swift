import Foundation
import Logging
import Models

public final class TestEntryConfigurationGenerator {
    
    private let validatedEnteries: [TestToRun: [TestEntry]]
    private let explicitTestsToRun: [TestToRun]
    private let testArgEntries: [TestArgFile.Entry]
    private let commonTestExecutionBehavior: TestExecutionBehavior
    private let commonTestDestinations: [TestDestination]
    private let commonBuildArtifacts: BuildArtifacts

    public init(
        validatedEnteries: [TestToRun: [TestEntry]],
        explicitTestsToRun: [TestToRun],
        testArgEntries: [TestArgFile.Entry],
        commonTestExecutionBehavior: TestExecutionBehavior,
        commonTestDestinations: [TestDestination],
        commonBuildArtifacts: BuildArtifacts
        )
    {
        self.validatedEnteries = validatedEnteries
        self.explicitTestsToRun = explicitTestsToRun
        self.testArgEntries = testArgEntries
        self.commonTestExecutionBehavior = commonTestExecutionBehavior
        self.commonTestDestinations = commonTestDestinations
        self.commonBuildArtifacts = commonBuildArtifacts
    }
    
    public func createTestEntryConfigurations() -> [TestEntryConfiguration] {
        log("Preparing test entry configurations for tests: \(explicitTestsToRun + testArgEntries.map { $0.testToRun })")
        let testEntryConfigurations = TestEntryConfiguration.createMatrix(
            testEntries: map(testsToRun: explicitTestsToRun),
            testDestinations: commonTestDestinations,
            testExecutionBehavior: commonTestExecutionBehavior,
            buildArtifacts: commonBuildArtifacts
        )
        let testArgFileEntryConfigurations = testArgEntries.flatMap { testArgFileEntry -> [TestEntryConfiguration] in
            let testEntries = map(testsToRun: [testArgFileEntry.testToRun])
            return testEntries.map {
                TestEntryConfiguration(
                    testEntry: $0,
                    testDestination: testArgFileEntry.testDestination,
                    testExecutionBehavior: TestExecutionBehavior(numberOfRetries: testArgFileEntry.numberOfRetries),
                    buildArtifacts: commonBuildArtifacts
                )
            }
        }
        return testEntryConfigurations + testArgFileEntryConfigurations
    }
    
    private func map(testsToRun: [TestToRun]) -> [TestEntry] {
        return validatedEnteries
            .filter { testsToRun.contains($0.key) }
            .flatMap { $0.value }
    }
}

