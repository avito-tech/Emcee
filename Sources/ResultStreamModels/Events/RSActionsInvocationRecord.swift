import Foundation

public struct RSActionsInvocationRecord: Codable, Equatable, RSTypedValue {
    public static var typeName: String { "ActionsInvocationRecord" }

    public let actions: RSArray<RSActionRecord>
    public let issues: RSResultIssueSummaries
    public let metadataRef: RSReference
    public let metrics: RSResultMetrics

    public init(
        actions: RSArray<RSActionRecord>,
        issues: RSResultIssueSummaries,
        metadataRef: RSReference,
        metrics: RSResultMetrics
    ) {
        self.actions = actions
        self.issues = issues
        self.metadataRef = metadataRef
        self.metrics = metrics
    }

    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        actions = try container.decode(RSArray<RSActionRecord>.self, forKey: .actions)
        issues = try container.decode(RSResultIssueSummaries.self, forKey: .issues)
        metadataRef = try container.decode(RSReference.self, forKey: .metadataRef)
        metrics = try container.decode(RSResultMetrics.self, forKey: .metrics)
    }
}

