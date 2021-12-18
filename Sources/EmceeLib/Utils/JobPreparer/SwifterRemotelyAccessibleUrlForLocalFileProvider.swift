import Foundation
import LocalHostDeterminer
import PathLib
import RESTMethods
import RESTServer
import RequestSender
import SocketModels
import Swifter
import Types
import UniqueIdentifierGenerator

public final class SwifterRemotelyAccessibleUrlForLocalFileProvider: RemotelyAccessibleUrlForLocalFileProvider {
    private let server: HTTPRESTServer
    private let requestSenderProvider: RequestSenderProvider
    private let queueServerAddress: SocketAddress
    private let serverRoot: AbsolutePath
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        server: HTTPRESTServer,
        requestSenderProvider: RequestSenderProvider,
        queueServerAddress: SocketAddress,
        serverRoot: AbsolutePath,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.server = server
        self.requestSenderProvider = requestSenderProvider
        self.queueServerAddress = queueServerAddress
        self.serverRoot = serverRoot
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
        
        let group = DispatchGroup()
        group.enter()
        var response: Either<WhatIsMyIpRequest.Response, RequestSenderError>?
        requestSenderProvider.requestSender(socketAddress: queueServerAddress).sendRequestWithCallback(
            request: WhatIsMyIpRequest(payload: WhatIsMyIpPayload()),
            callbackQueue: DispatchQueue(label: "SwifterRemotelyAccessibleUrlForLocalFileProvider.syncQueue"),
            callback: {
                response = $0
                group.leave()
            }
        )
        group.wait()
        
        let address: String
        switch response {
        case nil:
            throw Errors.missingResponse
        case .right(let error):
            throw error
        case .left(let response):
            address = response.address
        }
        
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
