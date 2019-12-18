import Foundation

public final class TestContext: Codable, Hashable, CustomStringConvertible {
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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(developerDir)
        hasher.combine(environment)
        hasher.combine(simulatorPath)
        hasher.combine(simulatorUdid)
        hasher.combine(testDestination)
    }
    
    public static func == (left: TestContext, right: TestContext) -> Bool {
        return left.developerDir == right.developerDir
            && left.environment == right.environment
            && left.simulatorPath == right.simulatorPath
            && left.simulatorUdid == right.simulatorUdid
            && left.testDestination == right.testDestination
    }
}
