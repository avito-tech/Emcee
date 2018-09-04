import Foundation

public struct Subprocess {
    public let arguments: [String]
    public let environment: [String: String]

    public init(arguments: [String], environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.arguments = arguments
        self.environment = environment
    }
}
