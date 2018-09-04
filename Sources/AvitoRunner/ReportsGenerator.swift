import ChromeTracing
import Foundation
import JunitReporting
import Logging
import Models

public final class ReportsGenerator {
    private let testingResult: CombinedTestingResults
    private let reportOutput: ReportOutput
    public init(testingResult: CombinedTestingResults, reportOutput: ReportOutput) {
        self.testingResult = testingResult
        self.reportOutput = reportOutput
    }
    
    public func prepareReports() throws {
        try createDirectories()
        try prepareJunitReport(testingResult: testingResult, path: reportOutput.junit)
        try prepareTraceReport(testingResult: testingResult, path: reportOutput.tracingReport)
    }
    
    private func createDirectories() throws {
        try FileManager.default.createDirectory(
            atPath: reportOutput.junit.deletingLastPathComponent,
            withIntermediateDirectories: true,
            attributes: nil)
        try FileManager.default.createDirectory(
            atPath: reportOutput.tracingReport.deletingLastPathComponent,
            withIntermediateDirectories: true,
            attributes: nil)
    }
    
    private func prepareJunitReport(testingResult: CombinedTestingResults, path: String) throws {
        let testCases = [testingResult.successfulTests, testingResult.failedTests]
            .flatMap { $0 }
            .map { (result: TestRunResult) -> JunitTestCase in
                let failures = result.exceptions.map {
                    JunitTestCaseFailure(
                        reason: $0.reason,
                        fileLine: "\($0.filePathInProject):\($0.lineNumber)")
                }
                let boundaries = JunitTestCaseBoundaries(
                    processId: result.processId,
                    simulatorId: result.simulatorId,
                    startTime: result.startTime,
                    finishTime: result.finishTime)
                return JunitTestCase(
                    caseId: result.testEntry.caseId,
                    className: result.testEntry.className,
                    name: result.testEntry.methodName,
                    time: result.duration,
                    isFailure: !result.succeeded,
                    failures: failures,
                    boundaries: boundaries)
        }
        
        let generator = JunitGenerator(testCases: testCases)
        do {
            try generator.writeReport(path: path)
            log("Stored Junit report at \(path)")
        } catch let error {
            log("Failed to write out junit report. Error: \(error)", color: .red)
            throw error
        }
    }
    
    private func prepareTraceReport(testingResult: CombinedTestingResults, path: String) throws {
        let generator = ChromeTraceGenerator(testingResult: testingResult)
        do {
            try generator.writeReport(path: path)
            log("Stored trace report at \(path)")
        } catch let error {
            log("Failed to write out trace report. Error: \(error)", color: .red)
            throw error
        }
    }
}

