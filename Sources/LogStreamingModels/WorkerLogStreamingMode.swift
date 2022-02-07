import Foundation

/// Defines if worker should stream its logs into queue or not.
public enum WorkerLogStreamingMode: Codable, Hashable {
    case enabled
    case disabled
}
