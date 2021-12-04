import Foundation
import PathLib

public struct Simulator: Hashable, CustomStringConvertible {
    public let testDestination: TestDestination
    public let udid: UDID
    public let path: AbsolutePath

    public init(testDestination: TestDestination, udid: UDID, path: AbsolutePath) {
        self.testDestination = testDestination
        self.udid = udid
        self.path = path
    }
    
    public var description: String {
        return "Simulator \(udid) \(testDestination.deviceType) \(testDestination.runtime) at \(path)"
    }
    
    public var simulatorSetPath: AbsolutePath {
        return path.removingLastComponent
    }
    
    public var devicePlistPath: AbsolutePath {
        return path.appending("device.plist")
    }
}
