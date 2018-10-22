import Basic
import Foundation
import Models
import ModelFactories

public protocol SubprocessArgument {
    func stringValue() throws -> String
}

extension String: SubprocessArgument {
    public func stringValue() throws -> String {
        return self
    }
}

extension ResourceLocation: SubprocessArgument {
    public func stringValue() throws -> String {
        return try ResourceLocationResolver.sharedResolver.resolvePath(resourceLocation: self).localPath
    }
}

extension AbsolutePath: SubprocessArgument {
    public func stringValue() throws -> String {
        return asString
    }
}
