import Foundation

public final class EnvironmentDefinedDsnExtractor: Error, CustomStringConvertible {
    private let envName: String
    
    private init(envName: String) {
        self.envName = envName
    }
    
    public static func dsnStringValue(
        envName: String = "EMCEE_SENTRY_DSN",
        environment: [String: String] = ProcessInfo.processInfo.environment)
        throws -> String
    {
        guard let providedEnvValue = environment[envName] else {
            throw EnvironmentDefinedDsnExtractor(envName: envName)
        }
        return providedEnvValue
    }
    
    public var description: String {
        return "Will not log to Sentry. You can provide Sentry DSN via \(envName) environment variable."
    }
}
