import Foundation

public final class PluginSupport {
    public static let pluginSocketEnv = "EMCEE_PLUGIN_SOCKET"
    public static let pluginIdentifierEnv = "EMCEE_PLUGIN_ID"
    
    enum `Error`: Swift.Error {
        case pluginSocketEnvIsNotDefined
        case pluginIdentifierEnvIsNotDefined
    }
    
    public static func pluginSocket() throws -> String {
        guard let value = ProcessInfo.processInfo.environment[pluginSocketEnv] else {
            throw Error.pluginSocketEnvIsNotDefined
        }
        return value
    }
    
    public static func pluginIdentifier() throws -> String {
        guard let value = ProcessInfo.processInfo.environment[pluginIdentifierEnv] else {
            throw Error.pluginIdentifierEnvIsNotDefined
        }
        return value
    }
}

