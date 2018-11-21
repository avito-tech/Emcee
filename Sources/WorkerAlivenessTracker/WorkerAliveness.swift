import Foundation

public enum WorkerAliveness: Equatable {
    case alive
    case silent
    case blocked
    case notRegistered
}
