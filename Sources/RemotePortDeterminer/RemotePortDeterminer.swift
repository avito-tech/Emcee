import Foundation
import Version

public protocol RemotePortDeterminer {
    func queryPortAndQueueServerVersion() -> [Int: Version]
}
