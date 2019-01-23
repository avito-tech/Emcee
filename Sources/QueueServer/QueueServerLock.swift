import Foundation

public protocol QueueServerLock {
    /// Defines if queue server is discoverable to clients for scheduling new jobs.
    var isDiscoverable: Bool { get }
}
