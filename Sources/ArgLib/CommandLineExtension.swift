import Foundation

public extension CommandLine {
    static let meaningfulArguments: [String] = Array(CommandLine.arguments.dropFirst())
    static let commandArguments: [String] = Array(meaningfulArguments.dropFirst())
}
