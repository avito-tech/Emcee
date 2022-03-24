import ChromeTracing
import CommonTestModels
import Foundation
import JunitReporting
import EmceeLogging
import PathLib
import ProcessController
import ResourceLocationResolver
import ResultBundleReporting
import TestArgFile
import Tmp

public final class ReportsGenerator {
    private let testingResult: CombinedTestingResults
    private let reportOutput: ReportOutput
    private let logger: ContextualLogger
    private let resourceLocationResolver: ResourceLocationResolver
    private let resultBundleGenerator: ResultBundleGenerator
    
    
    enum XcresultBundleError: Error, CustomStringConvertible {
        case missingResultBundle(path: AbsolutePath)
        
        var description: String {
            switch self {
            case .missingResultBundle(let path):
                return "Missing result bundle at path \(path)"
            }
        }
    }
    
    public init(
        logger: ContextualLogger,
        resourceLocationResolver: ResourceLocationResolver,
        testingResult: CombinedTestingResults,
        reportOutput: ReportOutput,
        resultBundleGenerator: ResultBundleGenerator
    ) {
        self.logger = logger
        self.resourceLocationResolver = resourceLocationResolver
        self.testingResult = testingResult
        self.reportOutput = reportOutput
        self.resultBundleGenerator = resultBundleGenerator
    }
    
    public func prepareReports() throws {
        if let junitPath = reportOutput.junit {
            try prepareJunitReport(
                testingResult: testingResult,
                path: resourceLocationResolver.resolvePath(
                    resourceLocation: .localFilePath(junitPath)
                ).directlyAccessibleResourcePath().pathString
            )
        }
        
        if let tracePath = reportOutput.tracingReport {
            try prepareTraceReport(
                testingResult: testingResult,
                path: resourceLocationResolver.resolvePath(
                    resourceLocation: .localFilePath(tracePath)
                ).directlyAccessibleResourcePath().pathString
            )
        }
        
        if let resultBundle = reportOutput.resultBundle {
            prepareResultBundleReport(
                testingResult: testingResult,
                path: try resourceLocationResolver.resolvePath(
                    resourceLocation: .localFilePath(resultBundle)
                ).directlyAccessibleResourcePath().pathString
            )
        }
        
        prepareConsoleReport(testingResult: testingResult)
    }
    
    private func prepareResultBundleReport(
        testingResult: CombinedTestingResults,
        path: String
    ) {
        do {
            try resultBundleGenerator.writeReport(
                path: path
            )
        } catch {
            logger.error("Failed to write out result bundle: \(error)")
        }
    }
    
    private func prepareJunitReport(testingResult: CombinedTestingResults, path: String) throws {
        try FileManager().createDirectory(
            atPath: path.deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        
        let testCases = testingResult.unfilteredResults
            .map { (testEntryResult: TestEntryResult) -> JunitTestCase in
                let testRunResult = testEntryResult.appropriateTestRunResult
                let failures = testRunResult.exceptions.map {
                    JunitTestCaseFailure(
                        reason: $0.reason,
                        fileLine: "\($0.filePathInProject):\($0.lineNumber)")
                }
                return JunitTestCase(
                    className: testEntryResult.testEntry.testName.className,
                    name: testEntryResult.testEntry.testName.methodName,
                    timestamp: testRunResult.startTime,
                    time: testRunResult.duration,
                    hostname: testRunResult.hostName,
                    isFailure: !testRunResult.succeeded,
                    failures: failures
                )
        }
        
        let generator = JunitGenerator(testCases: testCases)
        do {
            try generator.writeReport(path: path)
        } catch {
            logger.error("Failed to write out junit report: \(error)")
            throw error
        }
    }
    
    private func prepareTraceReport(testingResult: CombinedTestingResults, path: String) throws {
        try FileManager.default.createDirectory(
            atPath: path.deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        
        let generator = ChromeTraceGenerator(testingResult: testingResult)
        do {
            try generator.writeReport(path: path)
        } catch {
            logger.error("Failed to write out trace report: \(error)")
            throw error
        }
    }
    
    private func prepareConsoleReport(testingResult: CombinedTestingResults) {
        guard !testingResult.failedTests.isEmpty else {
            return logger.info("All \(testingResult.successfulTests.count) tests completed successfully")
        }
        logger.info("\(testingResult.successfulTests.count) tests completed successfully")
        logger.info("\(testingResult.failedTests.count) tests completed with errors")
        for testEntryResult in testingResult.failedTests {
            logger.info("Test \(testEntryResult.testEntry) failed after \(testEntryResult.testRunResults.count) runs")
            for testRunResult in testEntryResult.testRunResults {
                logger.info("   executed on \(testRunResult.hostName) at \(testRunResult.startTime.date.loggable()) using \(testRunResult.udid)")
                if !testRunResult.exceptions.isEmpty {
                    logger.info("   caught \(testRunResult.exceptions.count) exceptions")
                    for exception in testRunResult.exceptions {
                        logger.info("       \(exception)")
                    }
                } else {
                    logger.info("   no test exception has been caught")
                }
            }
        }
    }
}

private extension TestEntryResult {
    /// Returns a `TestRunResult` that can be used as a single result for this `TestEntry`.
    /// E.g. if there is any successful result, it will be returned. Otherwise, a failed result will be returned.
    var appropriateTestRunResult: TestRunResult {
        let appropriateTestRunResult: TestRunResult?
        
        let sorted = testRunResults.sorted { (left, right) -> Bool in
            return left.startTime > right.startTime
        }
        if succeeded {
            appropriateTestRunResult = sorted.first(where: { (result: TestRunResult) -> Bool in result.succeeded == true })
        } else {
            appropriateTestRunResult = sorted.first
        }
        
        return appropriateTestRunResult!
    }

}
