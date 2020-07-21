import DeveloperDirLocator
import DeveloperDirModels
import PathLib

public final class FakeDeveloperDirLocator: DeveloperDirLocator {
    public var result: AbsolutePath?

    public init(result: AbsolutePath? = nil) {
        self.result = result
    }
    
    public struct FakeError: Error, CustomStringConvertible {
        public var description: String = "FakeDeveloperDirLocator.result was not set, cannot resolve developer dir path"
    }
    
    public func path(developerDir: DeveloperDir) throws -> AbsolutePath {
        guard let result = result else {
            throw FakeError()
        }
        return result
    }
}
