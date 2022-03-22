import AppleTestModels
import CommonTestModels
import DeveloperDirModels
import Foundation
import PathLib
import SimulatorPoolModels

public struct AppleTestContext: Codable, Hashable, CustomStringConvertible {
    public let contextId: String
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let userInsertedLibraries: [String]
    public let simulator: Simulator
    public let testRunnerWorkingDirectory: TestRunnerWorkingDirectory
    public let testsWorkingDirectory: AbsolutePath
    public let testAttachmentLifetime: TestAttachmentLifetime
    
    public init(
        contextId: String,
        developerDir: DeveloperDir,
        environment: [String: String],
        userInsertedLibraries: [String],
        simulator: Simulator,
        testRunnerWorkingDirectory: TestRunnerWorkingDirectory,
        testsWorkingDirectory: AbsolutePath,
        testAttachmentLifetime: TestAttachmentLifetime
    ) {
        self.contextId = contextId
        self.developerDir = developerDir
        self.environment = environment
        self.userInsertedLibraries = userInsertedLibraries
        self.simulator = simulator
        self.testRunnerWorkingDirectory = testRunnerWorkingDirectory
        self.testsWorkingDirectory = testsWorkingDirectory
        self.testAttachmentLifetime = testAttachmentLifetime
    }
    
    public var description: String {
        return "<\(type(of: self)): contextId: \(contextId) simulator: \(simulator), developerDir: \(developerDir), testRunnerWorkingDirectory: \(testRunnerWorkingDirectory), testsWorkingDirectory: \(testsWorkingDirectory), env: \(environment), userInsertedLibraries: \(userInsertedLibraries), testAttachmentLifetime: \(testAttachmentLifetime)>"
    }
}
