import Foundation

public enum QueueServerError: Error, CustomStringConvertible {
    case noWorkers
    public var description: String {
        return "No alive workers"
    }
}
