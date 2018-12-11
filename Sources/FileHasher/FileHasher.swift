import Extensions
import Foundation
import Models

public final class FileHasher {
    private let fileUrl: URL
    private let hashValue = AtomicValue<String>("")

    public init(fileUrl: URL) {
        self.fileUrl = fileUrl
    }
    
    public func hash() throws -> String {
        return try hashValue.withExclusiveAccess { value in
            guard value.isEmpty else { return }
            let data = try Data(contentsOf: fileUrl)
            value = data.avito_sha256Hash().avito_hashStringFromSha256HashData()
        }
    }
}
