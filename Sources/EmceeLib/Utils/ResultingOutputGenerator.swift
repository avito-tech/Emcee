import CommonTestModels
import EmceeLogging
import Foundation
import ProcessController
import QueueModels
import ResourceLocationResolver
import TestArgFile
import ResultBundleReporting

public final class ResultingOutputGenerator {
    private let logger: ContextualLogger
    private let resourceLocationResolver: ResourceLocationResolver
    private let bucketResults: [BucketResult]
    private let commonReportOutput: ReportOutput
    private let testDestinationConfigurations: [TestDestinationConfiguration]
    private let resultBundleGenerator: ResultBundleGenerator

    public init(
        logger: ContextualLogger,
        resourceLocationResolver: ResourceLocationResolver,
        bucketResults: [BucketResult],
        commonReportOutput: ReportOutput,
        testDestinationConfigurations: [TestDestinationConfiguration],
        resultBundleGenerator: ResultBundleGenerator
    ) {
        self.logger = logger
        self.resourceLocationResolver = resourceLocationResolver
        self.bucketResults = bucketResults
        self.commonReportOutput = commonReportOutput
        self.testDestinationConfigurations = testDestinationConfigurations
        self.resultBundleGenerator = resultBundleGenerator
    }
    
    public func generateOutput() throws {
        let testingResults = bucketResults.compactMap { (bucketResult: BucketResult) -> TestingResult? in
            switch bucketResult {
            case .testingResult(let testingResult):
                return testingResult
            }
        }
        
        try generateOutput(testingResults: testingResults)
    }
    
    private func generateOutput(testingResults: [TestingResult]) throws {
        try generateDestinationSpecificOutputs(testingResults: testingResults)
        try generateCommonOutput(testingResults: testingResults)
    }
    
    private func generateDestinationSpecificOutputs(testingResults: [TestingResult]) throws {
        for testDestinationConfiguration in testDestinationConfigurations {
            try generateDestinationSpecificOutput(
                testDestinationConfiguration: testDestinationConfiguration,
                testingResults: testingResults
            )
        }
    }
    
    private func generateDestinationSpecificOutput(
        testDestinationConfiguration: TestDestinationConfiguration,
        testingResults: [TestingResult]
    ) throws {
        let matchingTestingResults = testingResults.filter {
            $0.testDestination == testDestinationConfiguration.testDestination
        }
        let combinedTestingResults = CombinedTestingResults(testingResults: matchingTestingResults)
        try generateOutput(
            combinedTestingResults: combinedTestingResults,
            reportOutput: testDestinationConfiguration.reportOutput
        )
    }
    
    private func generateCommonOutput(testingResults: [TestingResult]) throws {
        let combinedTestingResults = CombinedTestingResults(testingResults: testingResults)
        try generateOutput(combinedTestingResults: combinedTestingResults, reportOutput: commonReportOutput)
    }
    
    private func generateOutput(combinedTestingResults: CombinedTestingResults, reportOutput: ReportOutput) throws {
        let reportsGenerator = ReportsGenerator(
            logger: logger,
            resourceLocationResolver: resourceLocationResolver,
            testingResult: combinedTestingResults,
            reportOutput: reportOutput,
            resultBundleGenerator: resultBundleGenerator
        )
        try reportsGenerator.prepareReports()
    }
}
