import Foundation

public enum QueueServerTearDownPolicy: Codable {
    /// Queue server will automatically tear down after being idle for the given amout of time starting
    /// from the last job schedule event.
    case afterBeingIdle(period: TimeInterval)
    
    /// Queue server will stop accepting new jobs after the given period of time since the startup.
    /// All jobs that are still performing will be attempted to finish. New jobs won't be accepted.
    case finishAllJobsAndTearDown(period: TimeInterval)
    
    /// Queue server will attempt to stay alive for as long as possible.
    case stayAlive
    
    private enum CodingKeys: String, CodingKey {
        case caseId
        case period
    }
    
    private enum CaseId: String, Codable {
        case afterBeingIdle
        case finishAllJobsAndTearDown
        case stayAlive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)

        switch caseId {
        case .afterBeingIdle:
            self = .afterBeingIdle(period: try container.decode(TimeInterval.self, forKey: .period))
        case .finishAllJobsAndTearDown:
            self = .finishAllJobsAndTearDown(period: try container.decode(TimeInterval.self, forKey: .period))
        case .stayAlive:
            self = .stayAlive
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .afterBeingIdle(let period):
            try container.encode(CaseId.afterBeingIdle, forKey: .caseId)
            try container.encode(period, forKey: .period)
        case .finishAllJobsAndTearDown(let period):
            try container.encode(CaseId.finishAllJobsAndTearDown, forKey: .caseId)
            try container.encode(period, forKey: .period)
        case .stayAlive:
            try container.encode(CaseId.stayAlive, forKey: .caseId)
        }
    }
}
