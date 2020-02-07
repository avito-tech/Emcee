import Foundation
import PathLib

public protocol SubprocessArgument {
    func stringValue() throws -> String
}

extension String: SubprocessArgument {
    public func stringValue() throws -> String {
        return self
    }
}

extension AbsolutePath: SubprocessArgument {
    public func stringValue() throws -> String {
        return pathString
    }
}

public final class JoinedSubprocessArgument: SubprocessArgument, CustomStringConvertible {
    private let components: [SubprocessArgument]
    private let separator: String

    public init(components: [SubprocessArgument], separator: String) {
        self.components = components
        self.separator = separator
    }
    
    public func stringValue() throws -> String {
        return try components.map { try $0.stringValue() }.joined(separator: separator)
    }
    
    public var description: String {
        return components.map { "\($0)" }.joined(separator: " ")
    }
}
