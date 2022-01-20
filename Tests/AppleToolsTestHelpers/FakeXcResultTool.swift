import AppleTools
import PathLib
import ResultStreamModels
import Types

open class FakeXcResultTool: XcResultTool {
    public var result: Either<RSActionsInvocationRecord, Error>

    public static var defaultResult = RSActionsInvocationRecord(
        actions: [],
        issues: RSResultIssueSummaries(testFailureSummaries: []),
        metadataRef: RSReference(id: "metadataRef"),
        metrics: RSResultMetrics(testsCount: nil, testsFailedCount: nil, warningCount: nil)
    )

    public init(
        result: Either<RSActionsInvocationRecord, Error> = .success(FakeXcResultTool.defaultResult)
    ) {
        self.result = result
    }

    public func get(path: AbsolutePath) throws -> RSActionsInvocationRecord {
        try result.dematerialize()
    }
}
