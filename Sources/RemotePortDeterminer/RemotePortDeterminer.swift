import Foundation
import Version

public protocol RemotePortDeterminer {
    func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [Int: Version]
}
