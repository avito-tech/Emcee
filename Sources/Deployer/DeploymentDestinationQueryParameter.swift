import Foundation
import PathLib

enum DeploymentDestinationQueryParameterError: Error, CustomStringConvertible {
    case unknownParameter(name: String)
    case incorrectNumberOfSimulators(value: String)
    case valueIsNotProvidedForParameter(name: String)
    
    var description: String {
        switch self {
        case let .unknownParameter(name):
            return "Unknown deployment destination query parameter: \(name)"
        case let .incorrectNumberOfSimulators(value):
            return "Incorrect number for simulators: \(value)"
        case let .valueIsNotProvidedForParameter(name):
            return "Value is not provided for parameter: \(name)"
        }
    }
}

public enum DeploymentDestinationQueryParameter {
    case numberOfSimulators(UInt)
    case absoluteSshKey(path: AbsolutePath)
    case sshKey(name: String)
    
    public init(name: String, value: String?) throws {
        guard let value = value else {
            throw DeploymentDestinationQueryParameterError.valueIsNotProvidedForParameter(name: name)
        }
        
        switch name {
        case "numberOfSimulators":
            guard let numberOfSimulators = UInt(value) else {
                throw DeploymentDestinationQueryParameterError.incorrectNumberOfSimulators(
                    value: value
                )
            }
            self = .numberOfSimulators(numberOfSimulators)
        case "absoluteSshKeyPath":
            self = .absoluteSshKey(
                path: AbsolutePath(value)
            )
        case "sshKeyName":
            self = .sshKey(name: value)
        default:
            throw DeploymentDestinationQueryParameterError.unknownParameter(name: name)
        }
    }
}
