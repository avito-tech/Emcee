import Foundation

public enum QueueState: Equatable, CustomStringConvertible, Codable {
    /// Queue is executing its buckets normally
    case running(RunningQueueState)
    
    /// Queue has been deleted. Its buckets won't be dequeued, but workers may still execute previously dequeued buckets.
    case deleted

    public var description: String {
        switch self {
        case .running(let runningQueueState):
            return "<running: \(runningQueueState)>"
        case .deleted:
            return "<deleted>"
        }
    }

    private enum CaseId: String, Codable {
        case running
        case deleted
    }

    private enum CodingKeys: CodingKey {
        case caseId
        case runningQueueState
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .running:
            self = .running(try container.decode(RunningQueueState.self, forKey: .runningQueueState))
        case .deleted:
            self = .deleted
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .running(let runningQueueState):
            try container.encode(CaseId.running, forKey: .caseId)
            try container.encode(runningQueueState, forKey: .runningQueueState)
        case .deleted:
            try container.encode(CaseId.deleted, forKey: .caseId)
        }
    }
}
