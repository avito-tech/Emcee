import Foundation

public enum AutomaticTerminationPolicy: Codable {
    /// Will trigger termination after being idle for the given amout of time.
    case afterBeingIdle(period: TimeInterval)
    
    /// Will trigger termination after the given amount of time.
    case after(timeInterval: TimeInterval)
    
    /// Will not trigger automatic termination.
    case stayAlive
    
    public var period: TimeInterval {
        switch self {
        case .afterBeingIdle(let period):
            return period
        case .after(let timeInterval):
            return timeInterval
        case .stayAlive:
            return .infinity
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case caseId
        case period
    }
    
    private enum CaseId: String, Codable {
        case afterBeingIdle
        case after
        case stayAlive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)

        switch caseId {
        case .afterBeingIdle:
            self = .afterBeingIdle(period: try container.decode(TimeInterval.self, forKey: .period))
        case .after:
            self = .after(timeInterval: try container.decode(TimeInterval.self, forKey: .period))
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
        case .after(let period):
            try container.encode(CaseId.after, forKey: .caseId)
            try container.encode(period, forKey: .period)
        case .stayAlive:
            try container.encode(CaseId.stayAlive, forKey: .caseId)
        }
    }
}
