import Foundation

public final class EnvironmentDefinedValueExtractor: Error, CustomStringConvertible {
    private let envName: String
    
    private init(envName: String) {
        self.envName = envName
    }
    
    public static func value(
        envName: String,
        environment: [String: String] = ProcessInfo.processInfo.environment)
        throws -> String
    {
        guard let providedEnvValue = environment[envName] else {
            throw EnvironmentDefinedValueExtractor(envName: envName)
        }
        return providedEnvValue
    }
    
    public var description: String {
        return "\(envName) environment variable was not set."
    }
}
