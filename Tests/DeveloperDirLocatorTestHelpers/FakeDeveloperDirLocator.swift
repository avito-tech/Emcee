import DeveloperDirLocator
import Models
import PathLib

public final class FakeDeveloperDirLocator: DeveloperDirLocator {
    public var result: AbsolutePath?

    public init(result: AbsolutePath? = nil) {
        self.result = result
    }
    
    public struct FakeError: Error {}
    
    public func path(developerDir: DeveloperDir) throws -> AbsolutePath {
        guard let result = result else {
            throw FakeError()
        }
        return result
    }
}
