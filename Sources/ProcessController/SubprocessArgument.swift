import Basic
import Foundation
import Models

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
        return asString
    }
}
