import Foundation
import LocalHostDeterminer
import PathLib
import RESTServer
import Swifter
import UniqueIdentifierGenerator

public final class SwifterRemotelyAccessibleUrlForLocalFileProvider: RemotelyAccessibleUrlForLocalFileProvider {
    private let server: HTTPRESTServer
    private let serverRoot: AbsolutePath
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        server: HTTPRESTServer,
        serverRoot: AbsolutePath,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.server = server
        self.serverRoot = serverRoot
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public struct NoUrlError: Error, CustomStringConvertible {
        public let components: URLComponents
        public var description: String {
            "Failed to generate URL from components \(components)"
        }
    }
    
    public func remotelyAccessibleUrlForLocalFile(
        archivePath: AbsolutePath,
        inArchivePath: RelativePath
    ) throws -> URL {
        let path = serverRoot.appending(
            uniqueIdentifierGenerator.generate(),
            archivePath.lastComponent
        )
        
        server.add(
            requestPath: path,
            localFilePath: archivePath
        )
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = LocalHostDeterminer.currentHostAddress
        urlComponents.port = try server.port().value
        urlComponents.path = path.pathString
        urlComponents.fragment = inArchivePath.pathString
        guard let result = urlComponents.url else {
            throw NoUrlError(components: urlComponents)
        }
        return result
    }
}
