import DeveloperDirModels
import Foundation
import SimulatorPoolModels

public struct TestContext: Codable, Hashable, CustomStringConvertible {
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let simulatorPath: URL
    public let simulatorUdid: UDID
    public let testDestination: TestDestination
    
    public init(
        developerDir: DeveloperDir,
        environment: [String: String],
        simulatorPath: URL,
        simulatorUdid: UDID,
        testDestination: TestDestination
    ) {
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "<\(type(of: self)): simulator: \(simulatorUdid) \(testDestination), developerDir: \(developerDir), \(environment)>"
    }
}
