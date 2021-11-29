import DeveloperDirModels
import Foundation
import SimulatorPoolModels

public struct OnDemandSimulatorPoolKey: Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir
    public let testDestination: TestDestination
    
    public init(
        developerDir: DeveloperDir,
        testDestination: TestDestination
    ) {
        self.developerDir = developerDir
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "<\(type(of: self)): destination: \(testDestination), developerDir: \(developerDir)>"
    }
}
