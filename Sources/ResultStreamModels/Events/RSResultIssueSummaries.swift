import Foundation

public struct RSResultIssueSummaries: Codable, Equatable, RSTypedValue {
    public static var typeName: String { "ResultIssueSummaries" }

    public let testFailureSummaries: RSArray<RSTestFailureIssueSummary>?
//    public let warningSummaries: RSArray<RSIssueSummary>?

    public init(testFailureSummaries: RSArray<RSTestFailureIssueSummary>?) {
        self.testFailureSummaries = testFailureSummaries
    }

    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        testFailureSummaries = try container.decodeIfPresent(RSArray<RSTestFailureIssueSummary>.self, forKey: .testFailureSummaries)
    }
}
