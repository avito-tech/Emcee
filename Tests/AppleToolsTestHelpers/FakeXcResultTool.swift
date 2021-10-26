import AppleTools
import PathLib
import ResultStreamModels

open class FakeXcResultTool: XcResultTool {
    public var result: RSActionsInvocationRecord

    public static var defaultResult = RSActionsInvocationRecord(
        actions: [],
        issues: RSResultIssueSummaries(testFailureSummaries: []),
        metadataRef: RSReference(id: "metadataRef"),
        metrics: RSResultMetrics(testsCount: nil, testsFailedCount: nil, warningCount: nil)
    )

    public init(
        result: RSActionsInvocationRecord = FakeXcResultTool.defaultResult
    ) {
        self.result = result
    }

    public func get(path: AbsolutePath) throws -> RSActionsInvocationRecord {
        result
    }
}
