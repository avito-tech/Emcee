import Foundation
import PathLib

public struct Simulator: Hashable, CustomStringConvertible, Codable {
    public let simDeviceType: SimDeviceType
    public let simRuntime: SimRuntime
    public let udid: UDID
    public let path: AbsolutePath

    public init(
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
        udid: UDID,
        path: AbsolutePath
    ) {
        self.simDeviceType = simDeviceType
        self.simRuntime = simRuntime
        self.udid = udid
        self.path = path
    }
    
    public var description: String {
        return "Simulator \(udid) \(simDeviceType) \(simRuntime) at \(path)"
    }
    
    public var simulatorSetPath: AbsolutePath {
        return path.removingLastComponent
    }
    
    public var devicePlistPath: AbsolutePath {
        return path.appending("device.plist")
    }
}
