import Extensions
import Foundation

public final class SHA256NameKeyer: NameKeyer {
    public init() {}
    
    public func key(forName name: String) throws -> String {
        return try name.avito_sha256Hash()
    }
}
