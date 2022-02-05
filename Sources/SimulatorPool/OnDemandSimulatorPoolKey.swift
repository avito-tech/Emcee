import DeveloperDirModels
import Foundation
import SimulatorPoolModels
import TestDestination

public struct OnDemandSimulatorPoolKey: Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir
    public let testDestination: AppleTestDestination
    
    public init(
        developerDir: DeveloperDir,
        testDestination: AppleTestDestination
    ) {
        self.developerDir = developerDir
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "<\(type(of: self)): destination: \(testDestination), developerDir: \(developerDir)>"
    }
}
