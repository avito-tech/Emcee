import Foundation
import PathLib
import TestDestination

public struct Simulator: Hashable, CustomStringConvertible {
    public let testDestination: AppleTestDestination
    public let udid: UDID
    public let path: AbsolutePath

    public init(testDestination: AppleTestDestination, udid: UDID, path: AbsolutePath) {
        self.testDestination = testDestination
        self.udid = udid
        self.path = path
    }
    
    public var description: String {
        return "Simulator \(udid) \(testDestination.simDeviceType) \(testDestination.simRuntime) at \(path)"
    }
    
    public var simulatorSetPath: AbsolutePath {
        return path.removingLastComponent
    }
    
    public var devicePlistPath: AbsolutePath {
        return path.appending("device.plist")
    }
}
