import Foundation

public enum ReportAliveResponse: Codable, Equatable {
    case aliveReportAccepted
    
    private enum CodingKeys: CodingKey {
        case caseId
    }
    
    private enum CaseId: String, Codable {
        case aliveReportAccepted
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .aliveReportAccepted:
            self = .aliveReportAccepted
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .aliveReportAccepted:
            try container.encode(CaseId.aliveReportAccepted, forKey: .caseId)
        }
    }
}
