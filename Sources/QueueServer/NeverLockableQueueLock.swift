import Foundation

public final class NeverLockableQueueServerLock: QueueServerLock {
    public let isDiscoverable = true
    public init() {}
}
