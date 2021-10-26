import Foundation

public struct RSResultMetrics: Codable, Equatable, RSTypedValue {
    public static var typeName: String { "ResultMetrics" }

    public let testsCount: RSInt?
    public let testsFailedCount: RSInt?
    public let warningCount: RSInt?

    public init(
        testsCount: RSInt?,
        testsFailedCount: RSInt?,
        warningCount: RSInt?
    ) {
        self.testsCount = testsCount
        self.testsFailedCount = testsFailedCount
        self.warningCount = warningCount
    }

    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        testsCount = try container.decodeIfPresent(RSInt.self, forKey: .testsCount)
        testsFailedCount = try container.decodeIfPresent(RSInt.self, forKey: .testsFailedCount)
        warningCount = try container.decodeIfPresent(RSInt.self, forKey: .warningCount)
    }
}
