import Foundation

public struct RSActionResult: Codable, Equatable, RSTypedValue {
    public static var typeName: String { "ActionResult" }

//    public let coverage: RSCoverage
    public let diagnosticsRef: RSReference
    public let issues: RSResultIssueSummaries
    public let logRef: RSReference
    public let metrics: RSResultMetrics
    public let resultName: RSString
    public let status: RSString         // failed
    public let testsRef: RSReference

    public init(
        diagnosticsRef: RSReference,
        issues: RSResultIssueSummaries,
        logRef: RSReference,
        metrics: RSResultMetrics,
        resultName: RSString,
        status: RSString,
        testsRef: RSReference
    ) {
        self.diagnosticsRef = diagnosticsRef
        self.issues = issues
        self.logRef = logRef
        self.metrics = metrics
        self.resultName = resultName
        self.status = status
        self.testsRef = testsRef
    }

    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        diagnosticsRef = try container.decode(RSReference.self, forKey: .diagnosticsRef)
        issues = try container.decode(RSResultIssueSummaries.self, forKey: .issues)
        logRef = try container.decode(RSReference.self, forKey: .logRef)
        metrics = try container.decode(RSResultMetrics.self, forKey: .metrics)
        resultName = try container.decode(RSString.self, forKey: .resultName)
        status = try container.decode(RSString.self, forKey: .status)
        testsRef = try container.decode(RSReference.self, forKey: .testsRef)
    }
}
