import Foundation
import Logging
import Models

public final class ResultingOutputGenerator {
    private let testingResults: [TestingResult]
    private let commonReportOutput: ReportOutput
    private let testDestinationConfigurations: [TestDestinationConfiguration]

    public init(
        testingResults: [TestingResult],
        commonReportOutput: ReportOutput,
        testDestinationConfigurations: [TestDestinationConfiguration]) {
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
            testingResult: combinedTestingResults,
            reportOutput: reportOutput)
        try reportsGenerator.prepareReports()
    }
}
