import Foundation
import Version

public final class VersionProviderFixture: VersionProvider {
    private var predefinedVersion: String = UUID().uuidString
    private var shouldThrow = false
    
    public struct ExpectedError: Error {}
    
    public init() {}
    
    public func with(predefinedVersion: String) -> VersionProviderFixture {
        self.predefinedVersion = predefinedVersion
        return self
    }
    
    public func with(shouldThrow: Bool) -> VersionProviderFixture {
        self.shouldThrow = shouldThrow
        return self
    }
    
    public func buildVersionProvider() -> VersionProvider {
        return self
    }
    
    public func version() throws -> Version {
        guard !shouldThrow else { throw ExpectedError() }
        return Version(stringValue: predefinedVersion)
    }
}
