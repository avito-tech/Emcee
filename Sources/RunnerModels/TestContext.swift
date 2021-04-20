import DeveloperDirModels
import Foundation
import PathLib
import SimulatorPoolModels

public struct TestContext: Codable, Hashable, CustomStringConvertible {
    public let contextId: String
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let simulatorPath: AbsolutePath
    public let simulatorUdid: UDID
    public let testDestination: TestDestination
    public let testsWorkingDirectory: AbsolutePath
    
    public init(
        contextId: String,
        developerDir: DeveloperDir,
        environment: [String: String],
        simulatorPath: AbsolutePath,
        simulatorUdid: UDID,
        testDestination: TestDestination,
        testsWorkingDirectory: AbsolutePath
    ) {
        self.contextId = contextId
        self.developerDir = developerDir
        self.environment = environment
        self.simulatorPath = simulatorPath
        self.simulatorUdid = simulatorUdid
        self.testDestination = testDestination
        self.testsWorkingDirectory = testsWorkingDirectory
    }
    
    public var description: String {
        return "<\(type(of: self)): contextId: \(contextId) simulator: \(simulatorUdid) \(testDestination), developerDir: \(developerDir), testsWorkingDirectory: \(testsWorkingDirectory), env: \(environment)>"
    }
}
