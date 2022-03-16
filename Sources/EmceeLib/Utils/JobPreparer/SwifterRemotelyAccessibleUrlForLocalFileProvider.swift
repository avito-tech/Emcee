import Foundation
import PathLib
import RESTMethods
import RESTServer
import RequestSender
import SocketModels
import Swifter
import Types
import UniqueIdentifierGenerator
import WhatIsMyAddress

public final class SwifterRemotelyAccessibleUrlForLocalFileProvider: RemotelyAccessibleUrlForLocalFileProvider {
    private let server: HTTPRESTServer
    private let queueServerAddress: SocketAddress
    private let serverRoot: AbsolutePath
    private let synchronousMyAddressFetcherProvider: SynchronousMyAddressFetcherProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        queueServerAddress: SocketAddress,
        server: HTTPRESTServer,
        serverRoot: AbsolutePath,
        synchronousMyAddressFetcherProvider: SynchronousMyAddressFetcherProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.queueServerAddress = queueServerAddress
        self.server = server
        self.serverRoot = serverRoot
        self.synchronousMyAddressFetcherProvider = synchronousMyAddressFetcherProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public enum Errors: Error, CustomStringConvertible {
        case noUrlError(components: URLComponents)
        case missingResponse

        public var description: String {
            switch self {
            case .noUrlError(let components):
                return "Failed to generate URL from components \(components)"
            case .missingResponse:
                return "Missing response in SwifterRemotelyAccessibleUrlForLocalFileProvider"
            }
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
        
        let address = try synchronousMyAddressFetcherProvider.create(
            queueAddress: queueServerAddress
        ).fetch(
            timeout: 10
        )
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = address
        urlComponents.port = try server.port().value
        urlComponents.path = path.pathString
        urlComponents.fragment = inArchivePath.pathString
        guard let result = urlComponents.url else {
            throw Errors.noUrlError(components: urlComponents)
        }
        return result
    }
}
