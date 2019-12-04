import Foundation

/**
 * A command that should be invoked on the remote machine. Note it's expressible by string:
 *
 *        let deployableCommand = ["cp", .item(myItem, "file"), .item(myItem, "copy_of_file")]
 */
public final class DeployableCommand: ExpressibleByArrayLiteral, CustomStringConvertible {
    
    public typealias ArrayLiteralElement = DeployableCommandArg
    
    public let commandArgs: [DeployableCommandArg]
    
    public required init(arrayLiteral elements: DeployableCommandArg...) {
        self.commandArgs = elements
    }

    public init(_ commandArgs: [DeployableCommandArg]) {
        self.commandArgs = commandArgs
    }
    
    public var description: String {
        return commandArgs.map { $0.description }.joined(separator: " ")
    }
}

/**
 * A marker that object can be used as a remote deployment command argument.
 */
public enum DeployableCommandArg: ExpressibleByStringLiteral, Hashable, CustomStringConvertible {
    public typealias StringLiteralType = String
    
    /** A regular string argument. */
    case string(String)
    /**
     * A deployable item that will be "resolved" to its container path inside the deployment destination.
     * Additionally you can specify a relative path that will be added to the container path.
     */
    case item(DeployableItem, relativePath: String?)
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    public var description: String {
        switch self {
        case .string(let value):
            return value
        case .item(let deployableItem, let relativePath):
            if let relativePath = relativePath {
                return "\(deployableItem) with path: \(relativePath)"
            } else {
                return deployableItem.description
            }
        }
    }
}
