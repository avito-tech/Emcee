import DeveloperDirModels
import Foundation

public struct OnDemandSimulatorPoolKey: Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir
    public let simDeviceType: SimDeviceType
    public let simRuntime: SimRuntime
    
    public init(
        developerDir: DeveloperDir,
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime
    ) {
        self.developerDir = developerDir
        self.simDeviceType = simDeviceType
        self.simRuntime = simRuntime
    }
    
    public var description: String {
        return "<\(type(of: self)): \(simDeviceType) \(simRuntime) developerDir: \(developerDir)>"
    }
}
