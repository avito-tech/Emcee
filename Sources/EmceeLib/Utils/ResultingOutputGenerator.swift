import Foundation
import EmceeLogging
import QueueModels
import TestArgFile

public final class ResultingOutputGenerator {
    private let logger: ContextualLogger
    private let testingResults: [TestingResult]
    private let commonReportOutput: ReportOutput
    private let testDestinationConfigurations: [TestDestinationConfiguration]

    public init(
        logger: ContextualLogger,
        testingResults: [TestingResult],
        commonReportOutput: ReportOutput,
        testDestinationConfigurations: [TestDestinationConfiguration]
    ) {
        self.logger = logger
        self.testingResults = testingResults
        self.commonReportOutput = commonReportOutput
        self.testDestinationConfigurations = testDestinationConfigurations
    }
    
    public func generateOutput() throws {
        try generateDestinationSpecificOutputs()
        try generateCommonOutput()
    }
    
    private func generateDestinationSpecificOutputs() throws {
        for testDestinationConfiguration in testDestinationConfigurations {
            try generateDestinationSpecificOutput(testDestinationConfiguration: testDestinationConfiguration)
        }
    }
    
    private func generateDestinationSpecificOutput(testDestinationConfiguration: TestDestinationConfiguration) throws {
        let testingResults = self.testingResults.filter {
            $0.testDestination == testDestinationConfiguration.testDestination
        }
        let combinedTestingResults = CombinedTestingResults(testingResults: testingResults)
        try generateOutput(
            combinedTestingResults: combinedTestingResults,
            reportOutput: testDestinationConfiguration.reportOutput)
    }
    
    private func generateCommonOutput() throws {
        let combinedTestingResults = CombinedTestingResults(testingResults: testingResults)
        try generateOutput(combinedTestingResults: combinedTestingResults, reportOutput: commonReportOutput)
    }
    
    private func generateOutput(combinedTestingResults: CombinedTestingResults, reportOutput: ReportOutput) throws {
        let reportsGenerator = ReportsGenerator(
            logger: logger,
            testingResult: combinedTestingResults,
            reportOutput: reportOutput
        )
        try reportsGenerator.prepareReports()
    }
}
