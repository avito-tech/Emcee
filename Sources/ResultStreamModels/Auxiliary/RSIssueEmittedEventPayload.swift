import Foundation

public struct RSIssueEmittedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "IssueEmittedEventPayload"
    
    public let issue: RSTestFailureIssueSummary
    public let resultInfo: RSStreamedActionResultInfo
    public let severity: RSString
    
    public init(
        issue: RSTestFailureIssueSummary,
        resultInfo: RSStreamedActionResultInfo,
        severity: RSString
    ) {
        self.issue = issue
        self.resultInfo = resultInfo
        self.severity = severity
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        issue = try container.decode(RSTestFailureIssueSummary.self, forKey: .issue)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
        severity = try container.decode(RSString.self, forKey: .severity)
    }
}
