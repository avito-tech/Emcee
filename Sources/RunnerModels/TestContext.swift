import DeveloperDirModels
import Foundation
import SimulatorPoolModels

public struct TestContext: Codable, Hashable, CustomStringConvertible {
    public let contextUuid: UUID
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let simulatorPath: URL
    public let simulatorUdid: UDID
    public let testDestination: TestDestination
    
    public init(
        contextUuid: UUID,
        developerDir: DeveloperDir,
        environment: [String: String],
        simulatorPath: URL,
        simulatorUdid: UDID,
        testDestination: TestDestination
    ) {
        self.contextUuid = contextUuid
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.testDestination = testDestination
    }
    
    public var description: String {
        return "<\(type(of: self)): contextUuid: \(contextUuid) simulator: \(simulatorUdid) \(testDestination), developerDir: \(developerDir), \(environment)>"
    }
}
